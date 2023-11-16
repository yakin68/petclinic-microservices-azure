ANS_KEYPAIR="azurkeytest"
AWS_REGION="northeurope"
export ANSIBLE_INVENTORY="${WORKSPACE}/ansible/inventory/hosts.ini"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
export AZURE_SUBSCRIPTION_ID="88bbc84a-2800-40f2-b985-be5418274086"
export AZURE_CLIENT_ID="74197c47-694e-4f83-b6d2-4c2f82bf175b"
export AZURE_SECRET="b966e1e6-0214-4797-b9a1-15845a62413c"
export AZURE_TENANT="8388ef3f-c433-4ae9-8eff-e0cea679d269"
cd infrastructure/dev-k8s-terraform
sed -i "s/azurkeytest.pub/${ANS_KEYPAIR}.pub/g" main-master.tf main-worker-1.tf main-worker-2.tf
# Create key pair for Ansible, tf içindeki item değiştirmeyi unutma
ssh-keygen -m PEM -t rsa -b 2048 -f ~/workspace/test/infrastructure/keys/${ANS_KEYPAIR} || chmod 400 ${ANS_KEYPAIR}
terraform init
terraform apply -var-file="variables.tfvars" -auto-approve -no-color
ansible-inventory -v -i ./ansible/inventory/myazuresub.azure_rm.yaml --graph
ansible -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml all -m ping
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/k8s_setup.yaml

#ip değiştirelim masre ve worker ip
cd ~/workspace/test/infrastructure/keys/
ssh-copy-id -o StrictHostKeyChecking=no -i ~/workspace/test/infrastructure/keys/${ANS_KEYPAIR}.pub azureuser@98.71.90.56
ssh-copy-id -o StrictHostKeyChecking=no -i ~/workspace/test/infrastructure/keys/${ANS_KEYPAIR}.pub azureuser@98.71.90.56
ssh-copy-id -o StrictHostKeyChecking=no -i ~/workspace/test/infrastructure/keys/${ANS_KEYPAIR}.pub azureuser@98.71.90.56


ansible all -m ping

# Install k8s cluster on the infrastructure
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/k8s_setup.yaml
# Build, Deploy, Test the application
# Tear down the k8s infrastructure
cd infrastructure/dev-k8s-terraform
terraform destroy -auto-approve -no-color
# Delete key pair
aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR}
rm -rf ${ANS_KEYPAIR}