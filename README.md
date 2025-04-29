# Terraform CI/CD Infrastructure on AWS

This Terraform module provisions a complete CI/CD environment in AWS using the `us-east-2` region and a named profile (`minecraft`). The setup includes a VPC, public subnets, routing, EC2 instances for Jenkins, Prometheus, Grafana, and SonarQube, with security groups and IAM roles configured for access and automation.

---

## 🚀 Features

- **Custom VPC** with DNS support and public subnets
- **Internet Gateway** and **Route Tables** for internet access
- **Ubuntu and Amazon Linux 2 EC2 Instances** for:
  - Jenkins (t2.large, 50GB root volume)
  - Prometheus (t2.micro)
  - Grafana (t2.micro)
  - SonarQube (t2.medium)
- **Automated setup scripts** using `user_data` for each server
- **IAM Role & Instance Profile** for Jenkins with EC2 permissions
- **Security Group** allowing inbound access to:
  - `22` (SSH)
  - `80` (HTTP)
  - `443` (HTTPS)
  - `8080` (Jenkins)
  - `9000` (SonarQube)
  - `9090` (Prometheus)
  - `3000` (Grafana)

---

2) Slack Setup
    - Go to the bellow Workspace and create a Private Slack Channel and name it "yourfirstname-jenkins-cicd-pipeline-alerts"
    - Link: https://join.slack.com/t/jjtechtowerba-zuj7343/shared_invite/zt-24mgawshy-EhixQsRyVuCo8UD~AbhQYQ  
      - You can either join through the browser or your local Slack App
      - Create a `Private Channel` using the naming convention `YOUR_INITIAL--multi-microservices-alerts`
        - **NOTE:** *`(The Channel Name Must Be Unique, meaning it must be available for use)`*
      - Visibility: Select `Private`
      - Click on the `Channel Drop Down` and select `Integrations` and Click on `Add an App`
      - Search for `Jenkins` and Click on `View`
      - Click on `Configuration/Install` and Click `Add to Slack` 
      - On Post to Channel: Click the Drop Down and select your channel above `YOUR_INITIAL-multi-microservices-alerts`
      - Click `Add Jenkins CI Integration`
      - Scrol Down and Click `SAVE SETTINGS/CONFIGURATIONS`
      - Leave this page open
    

---
### 2A) Verify the Following Services are running in the Jenkins Instance
- SSH into the `Jenkins-CI` server
    - Run the following commands and confirm that the `services` are all `Running`
```bash
# Confirm Java version
sudo java --version

# Confirm that Jenkins is running
sudo systemctl status jenkins

# Confirm that docker is running
sudo systemctl status docker

# Confirm that Terraform is running
terraform version

# Confirm that the Kubectl utility is running 
kubectl version --client

# Confirm that AWS CLI is running
aws --version

# Confirm that the SonarQube container is running
docker ps | grep sonarqube:lts-community

# Lastly confirm that the `sonarqube-volume docker volume` was created
docker volume inspect volume sonarqube-volume
```

### 2A.2) Before Creating The Cluster, Delete Any EKS IAM Role In Your Account
- Navigate to the `IAM Servce`
  - Click on `Roles`
  - Use the `Search Bar` to file roles that starts with `eks`
  - Delete any Role with the name `eks`

### 2B) Deploy Your EKS Cluster Environment
- `UPDATE` Your Terraform Provider Region to `Your Choice REGION`*
    - **⚠️`NOTE:ALERT!`⚠️:** *Do Not Use North Virginia, that's US-EAST-1*
    - **⚠️`NOTE:ALERT!`⚠️:** *Also Confirm that The Selected Region Has A `Default VPC` You're Confident Has Internet Connection*
    - **⚠️`NOTE:ALERT!`⚠️:** *The Default Terraform Provider Region Defined In The Config Is **`Ohio(US-EAST-2)`***
- Confirm you're still logged into the `Jenkins-CI` Server via `SSH`
- Run the following commands to deploy the `EKS Cluster` in the `Jenkins-CI`
- **NOTE:** *You Can As Well Deploy The Cluster Using Terraform From Your Local System*

```bash
# Clone your project reporisoty
git clone https://github.com/Dappyplay4u/microservice-cicd.git

# cd and checkout into the DevSecOps project branch
cd Microservices\microservice-cicd\eks-cluster

# Deploy EKS Environment
terraform init
terraform plan
terraform apply --auto-approve
```
- Give it about `10 MINUTES` for the cluster creation to complete
- Then `Duplicate or Open` a New Console `Tab` and `Switch` to the `Ohio(us-east-2) Region`
- Navigate to `EKS` and confirm that your Cluster was created successfully with the name `EKS_Cluster`
- Also confirm there's no issue regarding your Terraform execution


#### **⚠️`NOTE:ALERT!`⚠️:** FOLLOW THESE STEPS ONLY IF YOUR CLUSTER CREATION FAILED
- If the Error Message says anything about `EKS IAM Roles` then...
- Destroy everything by running: `terraform destroy --auto-approve`
- Wait for everything to get destroy/terminated successfully.

- Then Navigate to `IAM`
  - In the `Search section`
  - Search for the word `EKS` and select ALL the EKS Role that shows up
  - Delete every one of them

- Go back to where you're executing Terraform(that's the Jenkins Instance)
  - Re-run: `terraform apply --auto-approve`
  - Wait for another `10 Minute` 

#### 2C) Once The Cluster Deployment Completes, Go Ahead and Enable The OIDC Connector/Provider
- Run this command from the `Jenkins-CI` instance
```bash
eksctl utils associate-iam-oidc-provider \
    --region us-east-2 \
    --cluster EKS_Cluster \
    --approve
```

#### 2D) Update/Get Cluster Credential: 
- Run this command from the `Jenkins-CI` instance
```bash
aws eks update-kubeconfig --name <clustername> --region <region>
```