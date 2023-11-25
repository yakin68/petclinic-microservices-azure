git add .
git commit -m 'pipeline test'
git push origin dev

git add .
git commit -m 'added terraform files for dev server'
git push --set-upstream origin feature/msp-5   ## git push -u origin feature/msp-5  // buda yazılabilir
git checkout dev
git merge feature/msp-5
git push origin dev
```

    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
        }

        failure {

            echo 'Delete the Image Repository on ECR due to the Failure'
            sh "az acr delete --name $ACR_REPO_NAME --yes"

            echo 'Deleting Terraform Stack due to the Failure'
            sh """
                cd infrastructure/dev-k8s-terraform
                terraform destroy -var-file="variables.tfvars" --auto-approve -no-color
            """

            echo "Delete existing key pair "
            sh """
                cd ${WORKSPACE}/infrastructure/dev-k8s-terraform/${ANS_KEYPAIR} 
                rm -f ${ANS_KEYPAIR}*
                cd ${WORKSPACE}
                rm -f ${ANS_KEYPAIR}*
            """
        }
    }    