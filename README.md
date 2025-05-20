# Terraform CI/CD Infrastructure on AWS

This Terraform module provisions a complete Continuous Integration / Continuous Deployment (CI/CD) environment in Amazon Web Services (AWS) using the `us-west-2` region. The setup includes a Virtual Private Cloud (VPC), public subnets, routing, Amazon Elastic Compute Cloud (EC2) instances for Jenkins, Prometheus, Grafana, and SonarQube, with security groups and Identity and Access Management (IAM) roles configured for access and automation.

Navigate to onlineboutique-infra/eks-cluster-ec2. Edit provider.tf and change the value of the "Name" to the AWS user account you intend to use (shown below)

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Name = "insert_aws_account_name_here"
    }
  }
}

Navigate to onlineboutique-infra/main-cicd. Edit ec2.tf and change the value of the "Name" to the AWS user account you intend to use (shown below):

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Name = "insert_aws_account_name_here"
    }
  }
}

Enter this to create a key for "postgres":

- aws ec2 create-key-pair --key-name postgreskey --query "KeyMaterial" --output text > postgreskey.pem

Verify
- aws ec2 describe-key-pairs --query "KeyPairs[*].KeyName"
- Ensure that the provate key is downloaded to your machine

Should show:

'''
[
    "postgreskey"
]
'''

If you encounter an issue using SSH to log into an EC2 instance, do the following:

- 1️⃣ Generate a New Key Pair Locally (On Your Mac):

ssh-keygen -t rsa -b 4096 -f new-key.pem

This creates new-key.pem (private key) and new-key.pem.pub (public key).
Store the private key (new-key.pem) securely—you’ll need it for future SSH logins.

- 2️⃣ Add the New Public Key to the Instance: Inside the EC2 Instance Connect session, run:

echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
Replace "PASTE_PUBLIC_KEY_HERE" with the contents of new-key.pem.pub.

This allows SSH access using the new key.

- 3️⃣ Set Proper Permissions:

chmod 600 ~/.ssh/authorized_keys

4️⃣ Exit the EC2 Instance Connect session.

Then SSH into Your Instance Using the New Key

- 1️⃣ Try connecting with your new private key:

ssh -i new-key.pem ubuntu@<EC2-Public-IP>

Replace <EC2-Public-IP> with your instance’s public IP address.

#### Amazon Elastic Kubernetes Service (EKS) CLUSTER
cd into eks-cluster-ec2 and enter:

- terraform init

![terraform init - 1](terraform-init.png)
![terraform init - 1](terraform-init-1b.png)

- terraform plan

![terraform plan - 1](terraform-plan.png)
![terraform plan - 2](terraform-plan-2b.png)

- terraform apply

![terraform apply - 1](terraform-apply-1.png)
![terraform apply - 2](terraform-apply-2.png)
![terraform apply - 3](terraform-apply-3.png)
![terraform apply - 4](terraform-apply-4.png)
![terraform apply - 4b](terraform-apply-4b.png)
![terraform apply - 5](terraform-apply-5.png)

This will automatically setup your EKS cluster.

#### CICD PIPELINE
cd into main-cicd and enter:

- terraform init
- terraform plan
- terraform apply

This will also automatically setup your instances for:
- sonaqube
- jenkins
- prometheus
- grafana

Get the IP external addresses of the following resources and save for use:

- Grafana_server_http_url = "http://xx.xx.xx.xx:xx"
- Prometheus_server_http_url = "http://xx.xx.xx.xx:xx"
- SonaQube_server_http_url = "http://xx.xx.xx.xx:xx"
- jenkins_server_http_url = "http://xx.xx.xx.xx:xx"

- ![CI-CD Infrasstructure](ci-cd-infrastructure.png)
- 
- ![microservice Architecture](architecture-1.png)

The architectural diagram above illustrates a DevSecOps CI/CD infrastructure on AWS, enhanced with observability using Prometheus and Grafana. Here's a breakdown of each component and their interaction:

#### Core Components & Flow

- 🏗️ Terraform-Based Provisioning infrastructure (EC2 instances, VPC, subnets, security groups)
- ☁️ AWS Cloud: The platform hosting all EC2 instances
- 🔁 CI/CD Pipeline (Orchestrated by Jenkins)
- 🧱 Jenkins
- 🧪 SonarQube: Used for SAST (Static Application Security Testing).
- 🛡 Snyk: performs Software Composition Analysis (SCA) for dependency vulnerabilities.
- 🐳 Docker: Jenkins builds and tags Docker images for microservices.
- 📜 OPA/Conftest: scans the Dockerfile for misconfigurations using policy-as-code
- ☸️ Kubernetes (EKS or self-managed): The target environment for application deployment.
- 🔍 Observability: 📊 Prometheus for gathering of metrics + 📈 Grafana for visualization of metrics
- 📣 Notifications: Slack Integration is configured in Jenkins.


### Jenkins setup
1) #### Access Jenkins

**Please ensure that you use the exact versions of plugins displayed in the screenshots to avoid deployment issues**

Retrieve your AWS EC2 Public IP by running:

![EC2 Instances](ec2-instances.png)

aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress"
    - Copy your Jenkins Public IP address and paste on the browser: http://<ExternalIP>:8080
    - Copy the Path from the Jenkins UI to get the Administrator password
      - On AWS console, click on the EC2 instance, click Connect using EC2 Instance Connect, and run the command once logged in: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
      - Copy the password and log into Jenkins
![jenkins signup](jenkins-signup.png)

### Note:  Jenkins URL 

- **`NOTE:`** Copy the Outputed Password and Paste in the `Administrator password` in Jenkins
    - Plugins: Choose `Install Suggested Plugings` 
    - Provide 
        - Username: **`admin`**
        - Password: **`admin`**
        - `Name` can be admin and for `Email` you can generate an random email address.
    - Click `Save and Continue`
    - Click on `Save and Finish`
    - - Click on `Start using Jenkins`
![getting started](<Screen Shot 2023-04-24 at 8.49.43 AM.png>)

2)  #### Plugin installations:
    - Click on `Manage Jenkins`
    - Click on `Plugins`
    - Click `Available`
    - Search and Install the following Plugings and `"Install"`
        - **SonarQube Scanner**
        - **Snyk**
        - **Multibranch Scan Webhook Trigger**
        - **Eclipse Temurin installer**
        - **Pipeline: Stage View**
        - **Docker**
        - **Docker Commons**
        - **Docker Pipeline**
        - **docker-build-step**
        - **Docker API**
        - **Kubernetes**
        - **Kubernetes CLI**
        - **Kubernetes Credentials**
        - **Kubernetes Client API**
        - **Kubernetes Credentials Provider**
        - **Kubernetes :: Pipeline :: DevOps Steps**
        - **Slack Notification**
        - **ssh-agent**
        - **BlueOcean**
        - **Build Timestamp**
        - **Prometheus Metrics**
  
    - Click on `Install`
    - Once all plugins are installed select/Check the Box **`Restart Jenkins when installation is complete and no jobs are running`**

![alt text](jenkins-setup-1.png)
![alt text](jenkins-setup-2.png)


- Refresh your Browser and Log back into Jenkins

3)  #### Global tools configuration:
    - Click on Manage Jenkins -->> Tools -->> Global Tool Configuration

![Global Tool Configuration](jenkins-tools.png)

- **JDK** 
        - Click on `Add JDK` -->> Make sure **Install automatically** is enabled 
        
        Note: By default the **Install Oracle Java SE Development Kit from the website** make sure to close that option by clicking on the "x" icon on the right-hand side of the box.
        - Name: `JDK17`
        - Click on `Add installer` and select `Install from adoptium.net`
        - Version: `jdk-17.0.8.1+1`
  
![Jenkins JDK](jenkins-jdk.png)

- **Gradle Installation**
      - Click on `Add Gradle`
      - Name: `Gradle`
      - Enable `Install automatically`
      - Version: `8.8`

![Jenkins Gradle](jenkins-gradle.png)

- **SonarQube Scanner** 
      - Click on `SonarScanner for MSBuild` 
      - Name: `SonarScanner`
      - Enable: `Install automatically`

![Jenkins SonarQube](jenkins-sonarqube.png)

- **Snyk Installations** 
      - Click on ``Add Snyk`
      - Name: `Snyk`
      - Enable: `Install automatically` 
      - Version: `latest`
      - Update policy interval (hours): `24`
      - OS platform architecture: `Auto-detection`

![Jenkins Snyk](jenkins-snyk.png)

- **Docker installations** 
      - Click on `Add Docker` 
      - Name: `Docker`
      - Enable: `Install automatically`
      - Click on `Add installer`
      - Select `Download from docker.com`
      - Docker version: `latest`

![Jenkins Docker](jenkins-docker.png)

Apply and save

4)  #### Credentials setup(SonarQube, Slack, DockerHub, Kubernetes and ZAP):
    - Click on `Manage Jenkins`
      - Click on `Credentials`
      - Click on `Stores scoped to Jenkins`
      - Click on `System`
      - Click on `Global Credentials (Unrestricted)`
      - Click on `Add Credentials`
      1)  ##### SonarQube secret token (SonarQube-Token)
          - ###### Generating SonarQube secret token:
              - Login to your SonarQube Application (http://SonarServer-Sublic-IP:9000)
              - If the server not come up on the browser, then check if the service is deployed by entering: sudo systemctl status sonar
              - If the service is not found, then connect to the server and run the shell script SonaQube-setup.sh
              - Try to connect again to the SonarQube server
                - Default username: **`admin`** 
                - Default password: **`admin`**
            - Click on `Login`
                - Old Password: **`admin`**
                - New Password: **`adminadmin`**
                - Confirm Password: **`adminadmin`**

            - Click on administration and click on projects, management

              - Click on `create project` (Create the `app-shipping-service` microservice test project)
                - Project display name: `app-shipping-service`
                - Project key: `app-shipping-service`
                - Main branch name: `app-shipping-service` 
              
              - Click on `Projects` (Create the `app-recommendation-service` microservice test project)
                - Project display name: `app-recommendation-service`
                - Project key: `app-recommendation-service`
                - Main branch name: `app-recommendation-service` 
              
              - Click on `Projects` (Create the `app-product-catalog-service` microservice test project)
                - Project display name: `app-product-catalog-service`
                - Project key: `app-product-catalog-service`
                - Main branch name: `app-product-catalog-service` 
              
              - Click on `Projects` (Create the `app-payment-service` microservice test project)
                - Project display name: `app-payment-service`
                - Project key: `app-payment-service`
                - Main branch name: `app-payment-service` 
              
              - Click on `Projects` (Create the `app-loadgenerator-service` microservice test project)
                - Project display name: `app-loadgenerator-service`
                - Project key: `app-loadgenerator-service`
                - Main branch name: `app-loadgenerator-service` 
              
              - Click on `Projects` (Create the `app-frontend-service` microservice test project)
                - Project display name: `app-frontend-service`
                - Project key: `app-frontend-service`
                - Main branch name: `app-frontend-service`
              
              - Click on `Projects` (Create the `app-email-service` microservice test project)
                - Project display name: `app-email-service`
                - Project key: `app-email-service`
                - Main branch name: `app-email-service` 
              
              - Click on `Projects` *(Create the `app-database` microservice test project)*
                - Project display name: `app-database`
                - Project key: `app-database`
                - Main branch name: `app-database` 
              
              - Click on `Projects` (Create the `app-currency-service` microservice test project)
                - Project display name: `app-currency-service`
                - Project key: `app-currency-service`
                - Main branch name: `app-currency-service` 
              
              - Click on `Projects` (Create the `app-checkout-service` microservice test project)
                - Project display name: `app-checkout-service`
                - Project key: `app-checkout-service`
                - Main branch name: `app-checkout-service` 
              
              - Click on `Projects` (Create the `app-cart-service` microservice test project)
                - Project display name: `app-cart-service`
                - Project key: `app-cart-service`
                - Main branch name: `app-cart-service` 
              
              - Click on `Projects` (Create the `app-ad-serverice` microservice test project)
                - Project display name: `app-ad-serverice`
                - Project key: `app-ad-serverice`
                - Main branch name: `app-ad-serverice

            - Generate a `Global Analysis Token`    *This is the Token you need for Authorization*
              - Click on the `User Profile / Administrator` icon at top right of SonarQube
              - Click on `My Account`
              - Click `Security`
              - `Generate Token:`   *Generate this TOKEN and Use in the Next Step to Create The SonarQube Credential* 
                - Name: `microservices-web-app-token`
                - Type: `Global Analysis Token`
                - Expires in: `30 days`
              - Click on `GENERATE`
              - NOTE: *`Save The Token Somewhere...`*   sqa_b39f9ce5e1312fe46ffc512f87b520726182e2c4

          - ###### Store Credentials:
              - Navigate back to Jenkins http://JENKINS_PUBLIC_IP:8080
              - Click on `Manage Jenkins` 
                - Click on `Jenkins System`
                - Click `Global credentials (unrestricted)`

          - ###### Store SonarQube Secret Token in Jenkins:     
              - Click on ``Add Credentials``
              - Kind: `Secret text`
              - Secret: `Paste the SonarQube TOKEN` value that we have created on the SonarQube server
              - ID: ``SonarQube-Credential``
              - Description: `SonarQube-Credential`
              - Click on `Create`

      2)  ##### Slack secret token (slack-token)
          - ###### Get The Slack Token:
          If you don't have a Slack channel or workspace to start with, do the following:

            - 1️⃣ Create a New Slack Workspace
              - Go to Slack Signup
              - Click “Create a Workspace”.
              - Enter your work email and click “Continue”.
              - Slack will send a verification code—enter it to proceed.
              - Name your workspace (e.g., DevSecOps-Team).
              - Set up your default Slack channel (e.g., cicd-alerts).
              - Invite your team (or skip this for now).
              - Click “Finish”—your workspace is ready! 🎉

            - 2️⃣ Create a Slack Channel for Jenkins Alerts
              - Inside Slack, click “Add a channel”.
              - Click “Create a channel”.
              - Set your channel name (e.g., devsecops-alerts).
              - Choose Public (for all workspace members) or Private (for specific users).
              - Click “Create” and invite team members. 
              - ON Slack (web interface), navifate to the channel you created in the format `YOUR_INITIAL-devsecops-cicd-alerts`.
              - Click on your `Channel Drop Down`.
              - Click on `Integrations` and Click on `Add an App`.
              - Click on `Jenkins CI` and Click on `Install`.
              - On the window that opens, click on `Add to Slack`.
              - Click on `Choose a Channel`.
              - Click on `Add Jenkins CI Integration`.
              - Scroll down the page and copy the token under Integaration settings.

          - ###### Create The Slack Credential For Jenkins:
              - Go back to Jekins and navigate to `Manage Jenkins` >> `Credentials` >> `System`
              - Click `Global credentials (unrestricted)` >> `Add Credentials`
              - Kind: Secret text            
              - Secret: Place the Integration Token Credential ID copied in the step above (Note: Generate for slack setup)
              - ID: `Slack-Credential`
              - Description: `Slack-Credential`
              - Click on `Create`  

3)  ##### DockerHub Credential (Username and Password)
      - ###### Login to Your DockerHub Account (You can CREATE one if you Don't have an Account)
      - Access DockerHub at: https://hub.docker.com/
              - Provide Username: `YOUR USERNAME`
              - Provide Username: `YOUR PASSWORD`
              - Click on `Sign In` or `Sign Up`    
                - **NOTE:** *If you have an account `Sign in` If not `Sign up`*

          - ###### DockerHub Credential (Username and Password)
	          - On Jenkins, navigate to `Manage Jenkins` >> `Credentials` >> `System`
            - Click `Global credentials (unrestricted)` >> `Add Credentials`
	          - Kind: Username with password                  
	          - Username: ``YOUR USERNAME``
	          - Password: ``YOUR PASSWORD``
	          - ID: ``DockerHub-Credential``
	          - Description: `DockerHub-Credential`
	          - Click on `Create`   

        - ###### Get Cluster Credential From Kube Config
            - `SSH` back into your `Jenkins-CI` server
            ###  aws configure
            - RUN the command: `aws eks update-kubeconfig --name <clustername> --region <region>`
            ###### aws eks update-kubeconfig --name online-shop-eks-cluster --region us-west-2
            - COPY the Cluster KubeConfig: `cat ~/.kube/config`
            - `COPY` the KubeConfig file content
                - You can use your `Notepad` or any other `Text Editor` as well
                - Open your Local `GitBash` or `Terminal`
                - Create a File Locally
                - RUN: `rm ~/Downloads/kubeconfig-secret.txt`
                - RUN: `touch ~/Downloads/kubeconfig-secret.txt`
                - RUN: `vi ~/Downloads/kubeconfig-secret.txt`
                - `PASTE` and `SAVE` the KubeConfig content in the file

         - ###### Create The Kubernetes Credential In Jenkins
            - Navigate back to Jenkins
            - Click on ``Add Credentials``
                - Click on `Jenkins System`
                - Click `Global credentials (unrestricted)`
            - Kind: `Secret File`          
            - File: Click ``Choose File``
                - **NOTE:** *Seletct the KubeConfig file you saved locally*
            - ID: ``Kubernetes-Credential``
            - Description: `Kubernetes-Credential`
            - Click on `Create`

            - ###### Create The aws key and secret access key
            - Navigate back to Jenkins
            - Click on ``Add Credentials``
                - Click on `Jenkins System`
                - Click `Global credentials (unrestricted)`
            - Kind:  Username with password
            - Username: Your AWS Access Key ID
            - Password: Your AWS Secret Access Key
            - ID: aws-credentials (or any ID you'll reference in the pipeline)
            - Description: AWS credentials for accessing EKS
            - Click on `Create`
            
      5) ##### Create the ZAP Dynamic Application Security Testing Server Credential
         - ###### Start by copying the `EC2 SSH Private Key File Content` of your `Jenkins-CI` Server
            - Open your `GitBash Terminal` or `MacOS Terminal` 
            - Navigate to the Location where your `Jenkins-CI` Server SSH Key is Stored *(Usually in **Downloads**)*
            - Run the Command `cat /Your_Key_PATH/YOUR_SSH_KEY_FILE_NAME.pem`
              - `Note:` Your `.pem` private key will most like be in `Downloads`
            - COPY the KEY content and Navigate back to Jenkins to store it...
        
         - ###### Create The ZAP Server SSH Key Credential in Jenkins
            - Navigate to the `Jenkins Global Credential Dash`
            - Click on `Create Credentials`
            - Scope: Select `Global......`
            - Type: Select `SSH Username with Private Key`
            - ID and Description: `OWASP-Zap-Credential`
            - Username: `ubuntu`
            - Private key: Select `Enter directly`
              - Key: Click on `Add`
              - Key: `Paste The Private Key Content You Copied`
            - Click on `Create`
      
      6) ##### Create Your Snyk Test (SCA) Credential
         - ###### Navigate to: https://snyk.com/
            - Click on `Sign Up`
            - Select `GitHub`
                - *Once you've logged into your **Snyk** account*
            - Click on `Your Name` below `Help` on the bottom left hand side of your Snyk Account
            - Click on `Account Settings`
            - Auth Token (KEY): Click on `Click To Show`
            - **COPY** the TOKEN and SAVE somewhere
        

        - ###### Create SNYK Credential in Jenkins
            - Click on ``Add Credentials``
            - Kind: `Secret text`
            - Secret: `Paste the SNYK TOKEN` 
            - ID: ``Snyk-API-Token``
            - Description: `Snyk-API-Token`
            - Click on `Create`


3)  #### Configure system:    
    1)  - Click on ``Manage Jenkins`` 
        - Click on ``System`` and navigate to the `SonarQube Servers` section
        - Click on Add `SonarQube`
        - Name: `Sonar-Server`
        - Server URL: http://<SONARQUBE_SERVER_IP>:9000
        - Server authentication token: Select `SonarQube-Credential`

    2)  - Still on `Manage Jenkins` and `Configure System`
        - Scroll down to the `Slack` Section (at the very bottom)
        - Go to section `Slack`
            - `NOTE:` *Make sure you still have the Slack Page that has the `team subdomain` & `integration token` open*
            - Workspace: **Provide the `Team Subdomain` value** (created above)
            - Credentials: select the `Slack-Credential` credentials (created above) 
            - Default channel / member id: `#PROVIDE_YOUR_CHANNEL_NAME_HERE`
            - Click on `Test Connection`
            - If successful, click on `Apply` and `Save`

    #### Configure AWS CLI on Jenkins CI server
      - Log into the Jenkins server
      - Enter: aws configure and enter your:
        - AWS Access key ID
        - AWS Access Key
        - Default region name: us-west-2
        - Default output format: json


4) ### 🛠 Step 1: Configure Prometheus to Scrape Metrics

Update the prometheus.yml config file on the Prometheus EC2 instance:
### path /etc/prometheus/prometheus.yml
scrape_configs:
  - job_name: 'jenkins'
  - metrics_path: /prometheus
static_configs:
  - targets: ['<jenkins-ec2-ip>:8080']

Save and restart Prometheus:
- sudo systemctl restart prometheus
- systemctl status prometheus

Ensure the yml file looks like this:

lobal:
  scrape_interval: 15s
  external_labels:
    monitor: 'prometheus'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']
  - job_name: 'node'
    ec2_sd_configs:
      - region: us-east-1
        port: 9100
  - job_name: 'jenkins'
    metrics_path: /prometheus
    ec2_sd_configs:
      - region: us-east-1
        port: 8080
        filters:
          - name: tag:Application
            values:
              - jenkins
    static_configs:
     - targets: ['JENKINS_SERVER_IP'] # should replace with the jenkins IP

Verify via Prometheus UI under Status > Targets
- targets: ['<prometheus-ec2-ip>:9090/targets']

![Prometheus](prometheus.png)


### 🛠 Step 2: Connect Prometheus as Data Source in Grafana
     - Log in to Grafana UI
     - Default username/password: admin; change to adminadmin
     - Navigate to Settings > Data Sources
     - Click Add Data Source
     - Select Prometheus
     - Configure:
     - URL: http://<prometheus-ec2-ip>:9090
     - Click Save & Test

### 📊 Step 3: Import Dashboards
     - In Grafana, click + > Import
     - Use a popular dashboard ID:
     - Jenkins (ID: 9964)
     - Set Prometheus as the data source
     - Click Import

![Grafana Dashboard](grafana-dashboard-display.png)

### 🚨 Step 4: Set Up Alerts  (optional)
   - Grafana Alerts
   - In Grafana, go to Alerting > Notification channels
   - Add email, Slack, or webhook as a contact point
   - Create an Alert Rule (e.g., high CPU on Jenkins or failed jobs)
   - Assign to dashboard panels

   If your Grafana version is 7.3.4, then do the foloowing:
  - ✅ Step 1: Open a Dashboard Panel
    - 1️⃣ Go to your Grafana Dashboard (where Jenkins metrics are displayed).
    - 2️⃣ Click Edit Panel on the panel where you want alerts.

  - ✅ Step 2: Enable Alerts in the Panel
    - 1️⃣ Inside the panel settings, navigate to the Alerts tab.
    - 2️⃣ Click "Create Alert" (this is where you set conditions).
    - 3️⃣ Configure your Thresholds (e.g., CPU > 80% triggers an alert).
    - 4️⃣ Set the Evaluation Frequency (e.g., check every 30 seconds).

  - ✅ Step 3: Attach Notification Channel
    - 1️⃣ Select the Notification Channel (created earlier).
    - 2️⃣ Click Save to apply the alert rule to the panel.

### Pipeline creation (Make Sure To Make The Following Updates First)
- UPDATE YOUR ``Jenkinsfiles...``

- Update your `Frontend Service` - `OWASP Zap Server IP` and `EKS Worker Node IP` in the `Jenkinsfile` on `Line 100`
  - `NOTE` to update the `Frontend Service`, you must `Switch` to the `Frontend Branch`by do the following:
    - Switch to the Frontend Branch: git checkout app-frontend-service
    - Verify You're on the Right Branch: git branch

- Update the `EKS Worker Node IP` with yours in the `Jenkinsfile` on `Line 100`
<!-- sh 'ssh -o StrictHostKeyChecking=no ubuntu@35.90.100.75 "docker run -t zaproxy/zap-weekly zap-baseline.py -t http://44.244.36.98:30000/" || true' -->
To do this you need to locate the Kubernetes worker notes by doing the following:
  - Download the Correct kubectl Binary (For macOS (Apple Silicon - M1/M2))
    - curl -LO "https://dl.k8s.io/release/v1.29.0/bin/darwin/amd64/kubectl"
  - Make kubectl Executable
    - chmod +x kubectl
  - Move kubectl to System Path
    - sudo mv kubectl /usr/local/bin/
  - Verify Installation
    - kubectl version --client
  - Connect to your EKS cluster
    - aws eks update-kubeconfig --name <YOUR_CLUSTER_NAME> --region <AWS_REGION>
  - Verify your EKS nodes with:
    - kubectl get nodes -o wide

The ZAP server is Jenkins CI server.

**Note: This part is to be completed in all microservice branches**
- Update your `Slack Channel Name` in the `Jenkinsfiles...` - `All Microservices` on `Line 126`
<!-- slackSend channel: '#all-minecraftapp', -->
- Update `SonarQube projectName` of your Microservices in the `Jenkinsfiles...` - `All Microservices`
- Update the `SonarQube projectKey` of your Microservices in the `Jenkinsfiles...` - `All Microservices`
- Update the `DockerHub username` of your Microservices in the `Jenkinsfiles...` - `All Microservices`, provide Yours
- Ensure you change the Docker username of the checkout section
- Update the `DockerHub username/Image name` in all the `deployment.yaml` files for `test-env` and `prod-env` folders in `deploy-envs` folder across `Every Single Microservice Branch`
    
    - Log into Jenkins: http://Jenkins-Public-IP:8080/
    - Click on `New Item`
    - Enter an item name: `Online-Shop-Microservices-CICD-Automation` 
    - Select the category as **`Multibranch Pipeline`**
    - Click `OK`
    - At BRANCH SOURCES, clock `Add source`:
      - Git:
        - Project Repository
          - Repository URL: `Provide Your microservices Project Repo Git URL` 
    - BEHAVIORS
      - Set it to: `Discover Branches` and
      - Click `Add`
        - Select: `Filter by name (with wildcards)`
        - Include: `app-*`
    - Property strategy: `All branches get the same properties`
    - BUILD CONFIGURATION
      - Mode: Select `by Jenkinsfile`
      - Script Path: `Jenkinsfile`
    - SCAN MULTIBRANCH PIPELINE TRIGGER
      - Select `Scan by webhook`
      - Trigger token: `automation`
    - Click on `Apply` and `Save`
    
    - CONFIGURE MULTIBRANCH PIPELINE WEBHOOK
      - Copy this URL and Update the Jenkins IP (to yours): `http://PROVIDE_YOUR_JENKINS_IP:8080/multibranch-webhook-trigger/invoke?token=automation`

      - Navigate to your `Project Repository` on GitHub
        - Click on `Settings` in the Repository
        - Click on `Webhooks`
        - Click on `Add Webhook`
        - Payload URL: `http://PROVIDE_YOUR_JENKINS_IP:8080/multibranch-webhook-trigger/invoke?token=automation`
        - Content type: `application/json`
        - Which events would you like to trigger this webhook: Select `Just the push event`
        - Enable `Active`
        - Click `ADD WEBHOOK`

### Navigate Back To Jenkins and Confirm That All 12 Pipeline Jobs Are Running (11 Microservices Jobs and 1 DB Job)
  - Click on the `Jenkins Pipeline Job Name`
  - Click on `Scan Multibranch Pipeline Now`

### Confirm That All Microservices Branch Pipelines Succeeded (If Not, Troubleshoot)

![Pipeline Deployment 1](pipeline-deployment-1.png)
![Pipeline Deployment 2](pipeline-deployment-2.png)
![Pipeline Deployment 3](pipeline-deployment-3.png)

### SonarQube Code Inspection Result For All Microservices Source Code
  
![SonarQube Code Inspection](sonarqube-code-analysis.png)

### Also Confirm You Have All Service Deployment/Docker Artifacts In DockerHub

![Docker Containers](docker-containers.png)

### PERFORM THE DEPLOYMENT IN THE STAGING ENVIRONMENT/NAMESPACE (EKS CLUSTER)
- To perform the DEPLOYMENT in the staging Envrionment 
- You Just Have To `UNCOMMENT` the `DEPLOY STAGE` in the `Jenkinsfiles.....` and `PUSH` to GitHub
- DEPLOY the Microservices in the STAGING Environment in the following ORDER (To Resolve DEPENDENCIES around the SERVICES)

1. *`Redis DB`*
2. *`Product Catalog Service`*
3. *`Email Service`*
4. *`Currency Service`*
5. *`Payment Service`*
6. *`Shipping Service`*
7. *`Cart Service`*
8. *`Ad Service`*
9. *`Recommendation Service`*
10. *`Checkout Service`*
11. *`Frontend`*
12. *`Load Generator`*

  ### A. Test Application Access From the `Test/Stagging-Environment` Using `NodePort` of one of your Workers
  - SSH Back into your `Jenkins-CI` Server
      - RUN: `kubectl get svc -n test-env`
      - **NOTE:** COPY the Exposed `NodePort Port Number`
  
  ![Node Port - Test](services-prod-test-envs.png)

  - Access The Application Running in the `Test Environment` within the Cluster
  - `Update` the EKS Cluster Security Group ***(If you've not already)***
    - To do this, navigate to `EC2`
    - Select one of the `Worker Nodes` --> Click on `Security` --> Click on `The Security Group ID`
    - Click on `Edit Inbound Rules`: Port = `30000` and Source `0.0.0.0/0`
  - Open your Browser
  - Go to: http://YOUR_KUBERNETES_WORKER_NODE_IP:30000
  ![online shop](onlineshop.png)
  - Stage Deployment Succeeded

### PERFORM THE DEPLOYMENT NOW TO THE PRODUCTION ENVIRONMENT/NAMESPACE (EKS CLUSTER)
- To perform the DEPLOYMENT to the Prod Envrionment 
- You Just Have To `UNCOMMENT` the `DEPLOY STAGE` in the `Jenkinsfiles.....` and `PUSH` to GitHub
- DEPLOY the Microservices to the Prod Environment in the following ORDER (To Resolve DEPENDENCIES around the SERVICES)

1. *`Redis DB`*
2. *`Product Catalog Service`*
3. *`Email Service`*
4. *`Currency Service`*
5. *`Payment Service`*
6. *`Shipping Service`*
7. *`Cart Service`*
8. *`Ad Service`*
9. *`Recommendation Service`*
10. *`Checkout Service`*
11. *`Frontend`*
12. *`Load Generator`*

  - Confirm That Your Production Deployment Succeeded
  ![ProdEnv]() 
      - To access the application running in the `Prod-Env`
      - Navigate back to the `Jenkins-CI` shell 
      - RUN: `kubectl get svc -n prod-env`
      - Copy the LoadBalancer DNS and Open on a TAB on your choice Browser http://PROD_LOADBALANCER_DNS
    
  ![Node Port - Prod](services-prod-test-envs.png)


  - Snyk SCA Test Result
  ![snyk scan](<snyk scan.png>)

  - Test/Scan Dockerfiles with Open Policy Agent (OPA)


  - Slack Continuous Feedback Alert

  ![Slack CI-CD Notification](slack-cicd-notification-success.png)
  
![Website Deployment-1](website-deployment.png)
![Website Deployment-2](website-deployment-2.png)
![Website Deployment-mobile](website-deployment-mobile.png)

### Congratulations Your Deployment Was Successful
