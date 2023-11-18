az login
ANS_KEYPAIR="azurkeytest"
AWS_REGION="northeurope"
AZ_RG="mysshkey"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
# Create key pair for Ansible
ssh-keygen -m PEM -t rsa -b 2048 -f ${WORKSPACE}/${ANS_KEYPAIR} || chmod 400 ${ANS_KEYPAIR}
az sshkey create --location ${AWS_REGION} --resource-group ${AZ_RG} --name ${ANS_KEYPAIR}

# Create infrastructure for kubernetes
cd infrastructure/dev-k8s-terraform
sed -i "s/azurkeytest.pub/${ANS_KEYPAIR}.pub/g" main-master.tf main-worker-1.tf main-worker-2.tf
terraform init
terraform apply -var-file="variables.tfvars" -auto-approve -no-color
# Install k8s cluster on the infrastructure
ansible-playbook -i ${WORKSPACE}/ansible/inventory/myazuresub.azure_rm.yaml ./ansible/playbooks/k8s_setup.yaml
# Build, Deploy, Test the application
# Tear down the k8s infrastructure
cd infrastructure/dev-k8s-terraform
terraform destroy -var-file="variables.tfvars" -auto-approve -no-color
# Delete key pair
az sshkey delete --resource-group ${AZ_RG} --name ${ANS_KEYPAIR}
rm -rf ${ANS_KEYPAIR}
rm -rf ${ANS_KEYPAIR}.pub