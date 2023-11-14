#! /bin/bash

# update os
sudo apt-get update

# set server hostname as jenkins-server
sudo hostnamectl set-hostname jenkins-server
sudo chown -R azureuser:azureuser /home/azureuser

# install git
sudo apt-get install git -y

# install java 11
sudo apt-get install openjdk-11-jdk -y

# install jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins

# install docker
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker azureuser
sudo usermod -a -G docker jenkins

# configure docker as cloud agent for jenkins
sudo cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
sudo sed -i 's/^ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H tcp:\/\/127.0.0.1:2376 -H unix:\/\/\/var\/run\/docker.sock/g' /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl restart jenkins

# install docker compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# install python 3
sudo apt-get install python3-dev -y
sudo apt-get install python3-pip -y


# install ansible
pip install ansible -y

# install boto3
pip install boto3 botocore

# install terraform
sudo apt install unzip
sudo wget https://releases.hashicorp.com/terraform/1.4.6/terraform_1.4.6_linux_amd64.zip
sudo unzip terraform_1.4.6_linux_amd64.zip -d /usr/local/bin

# az install 
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

cd /home/azureuzer
sudo git clone https://github.com/yakin68/petclinic-microservices-azure.git

