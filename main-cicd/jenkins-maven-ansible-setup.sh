#!/bin/bash
# Update the system
yum update -y
# Install Java 17 (Amazon Corretto)
amazon-linux-extras enable corretto17
yum install -y java-17-amazon-corretto-devel
# Add Jenkins repository
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
# Install Jenkins
yum install -y jenkins
# Start and enable Jenkins service
systemctl enable jenkins
systemctl start jenkins
# Wait for Jenkins to initialize
echo "Waiting for Jenkins to start..."
sleep 30
# Retrieve and display initial admin password
echo "Jenkins initial admin password:"
cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Password file not ready yet. Try again in a few minutes."
# Optional: Open firewall port 8080 if using firewalld
# systemctl status firewalld >/dev/null 2>&1
# if [ $? -eq 0 ]; then
#     firewall-cmd --permanent --add-port=8080/tcp
#     firewall-cmd --reload
# fi
echo "Setup complete!"

# Installing Git
sudo yum install git -y

# Installing maven - commented out as usage of tools explanation is required.
# sudo wget https://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
# sudo sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
# sudo yum install -y apache-maven

# Java installation
# sudo yum install java-1.8.0-openjdk -y
# sudo amazon-linux-extras install java-openjdk11 -y

# Installing Ansible
sudo amazon-linux-extras install ansible2 -y
sudo yum install python-pip -y
sudo pip install boto3
sudo useradd ansadmin
sudo echo ansadmin:ansadmin | chpasswd
sudo sed -i "s/.*#host_key_checking = False/host_key_checking = False/g" /etc/ansible/ansible.cfg
sudo sed -i "s/.*#enable_plugins = host_list, virtualbox, yaml, constructed/enable_plugins = aws_ec2/g" /etc/ansible/ansible.cfg
sudo ansible-galaxy collection install amazon.aws

# Setup terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

# Install Docker
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -aG docker jenkins
sudo systemctl restart docker

# Install kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.25.9/2023-05-11/bin/linux/amd64/kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.25.9/2023-05-11/bin/linux/amd64/kubectl.sha256
sha256sum -c kubectl.sha256
openssl sha1 -sha256 kubectl
sudo chmod +x ./kubectl
sudo mkdir -p $HOME/bin && sudo cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
sudo echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc

# Install aws eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version