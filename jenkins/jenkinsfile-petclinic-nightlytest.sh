pipeline {
    agent any
    environment {
        APP_NAME="petclinic"
        ACR_REPO_NAME="yakin${APP_NAME}dockerimage"
        ACR_REPO_HELM_NAME="helmchart"

        AZ_REGION="northeurope"

        ACR_REGISTRY="${ACR_REPO_NAME}.azurecr.io"
        ACR_REGISTRY_HELM="${ACR_REPO_HELM_NAME}.azurecr.io"

        ACR_RESOURCE_GROUP="docker-helmchart"
        ANS_KEYPAIR="petclinic-${APP_NAME}-dev-${BUILD_NUMBER}.key"
        ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
        ANSIBLE_HOST_KEY_CHECKING="False"

    }
    stages {
        stage('Create ECR Repo') {
            steps {
                echo "Creating ACR Repo for ${APP_NAME} app"
                sh '''
                    az config set core.allow_broker=true
                    az account clear
                    az login

                    az acr show --name $ACR_REPO_NAME \
                    --resource-group $ACR_RESOURCE_GROUP || \
                            az acr create --name $ACR_REPO_NAME \
                            --resource-group $ACR_RESOURCE_GROUP \
                            --sku Basic --location $AZ_REGION --admin-enabled true

                    az acr show --name $ACR_REPO_HELM_NAME \
                    --resource-group $ACR_RESOURCE_GROUP || \
                            az acr create --name $ACR_REPO_HELM_NAME \
                            --resource-group $ACR_RESOURCE_GROUP \
                            --sku Basic --location $AZ_REGION --admin-enabled true

                '''
            }
        }
        stage('Package Application') {
            steps {
                echo 'Packaging the app into jars with maven'
                sh ". ./jenkins/package-with-maven-container.sh"
            }
        }
        stage('Prepare Tags for Docker Images') {
            steps {
                echo 'Preparing Tags for Docker Images'
                script {
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-admin-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_ADMIN_SERVER="${ACR_REGISTRY}/${ACR_REPO_NAME}:admin-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-api-gateway/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_API_GATEWAY="${ACR_REGISTRY}/${ACR_REPO_NAME}:api-gateway-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-config-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CONFIG_SERVER="${ACR_REGISTRY}/${ACR_REPO_NAME}:config-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-customers-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_CUSTOMERS_SERVICE="${ACR_REGISTRY}/${ACR_REPO_NAME}:customers-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-discovery-server/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_DISCOVERY_SERVER="${ACR_REGISTRY}/${ACR_REPO_NAME}:discovery-server-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-hystrix-dashboard/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_HYSTRIX_DASHBOARD="${ACR_REGISTRY}/${ACR_REPO_NAME}:hystrix-dashboard-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-vets-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VETS_SERVICE="${ACR_REGISTRY}/${ACR_REPO_NAME}:vets-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    MVN_VERSION=sh(script:'. ${WORKSPACE}/spring-petclinic-visits-service/target/maven-archiver/pom.properties && echo $version', returnStdout:true).trim()
                    env.IMAGE_TAG_VISITS_SERVICE="${ACR_REGISTRY}/${ACR_REPO_NAME}:visits-service-v${MVN_VERSION}-b${BUILD_NUMBER}"
                    env.IMAGE_TAG_GRAFANA_SERVICE="${ACR_REGISTRY}/${ACR_REPO_NAME}:grafana-service"
                    env.IMAGE_TAG_PROMETHEUS_SERVICE="${ACR_REGISTRY}/${ACR_REPO_NAME}:prometheus-service"
                }
            }
        }
        stage('Build App Docker Images') {
            steps {
                echo 'Building App Dev Images'
                sh ". ./jenkins/build-dev-docker-images-for-ecr.sh"
                sh 'docker image ls'
            }
        }
        stage('Push Images to ECR Repo') {
            steps {
                echo "Pushing ${APP_NAME} App Images to ECR Repo"
                sh ". ./jenkins/push-dev-docker-images-to-ecr.sh"
            }
        } 

         stage('Create Kubernetes Cluster for QA Automation Build') {
            steps {
                echo "Setup Kubernetes cluster for ${APP_NAME} App"
                sh "ansible-playbook -i ./ansible/inventory/myazuresub.azure_rm.yaml ./ansible/playbooks/k8s_setup.yaml"
            }
        }

        stage('Deploy App on Kubernetes cluster'){
            steps {
                echo 'Deploying App on Kubernetes'
                sh "envsubst < k8s/petclinic_chart/values-template.yaml > k8s/petclinic_chart/values.yaml"
                sh "sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart/Chart.yaml"
                sh """

                    helm package k8s/petclinic_chart

                    USER_NAME="helmtoken"
                    PASSWORD=$(az acr token create -n $USER_NAME -r $ACR_NAME --scope-map _repositories_admin --only-show-errors --query "credentials.passwords[0].value" -o tsv)
                
                    helm registry login ${ACR_REGISTRY_HELM} \
                    --username $USER_NAME \
                    --password $PASSWORD
                    
                    helm push petclinic_chart-${BUILD_NUMBER}.tgz oci://${ACR_REGISTRY_HELM}/stable-petclinic
                """    
                sh "envsubst < ansible/playbooks/dev-petclinic-deploy-template > ansible/playbooks/dev-petclinic-deploy.yaml"
                sh "sleep 60"    
                sh "ansible-playbook -i ./ansible/inventory/myazuresub.azure_rm.yaml ./ansible/playbooks/dev-petclinic-deploy.yaml"
            }
        }

        stage('Destroy the infrastructure'){
            steps{
                timeout(time:5, unit:'DAYS'){
                    input message:'Approve terminate'
                }
                sh """
                    docker image prune -af
                    az acr delete --name $ACR_REPO_NAME --yes
                    az acr delete --name $ACR_REPO_HELM_NAME --yes



                """
            }
        }        
    }
    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
        }

        failure {

            echo 'Delete the Image Repository on ECR due to the Failure'
            sh "az acr delete --name $ACR_REPO_NAME --yes "

            echo 'Delete the Image Repository on ECR due to the Failure'
            sh "az acr delete --name $ACR_REPO_HELM_NAME --yes "

        }
    }        
}