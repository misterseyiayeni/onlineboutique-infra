### 1A) Before Creating The Cluster, Delete Any EKS IAM Role In Your Account
- Navigate to the `IAM Servce`
  - Click on `Roles`
  - Use the `Search Bar` to file roles that starts with `eks`
  - Delete any Role with the name `eks`

### 2B) Deploy Your EKS Cluster Environment
- `UPDATE` Your Terraform Provider Region to `Your Choice REGION`*
    - **⚠️`NOTE:ALERT!`⚠️:** *Do Not Use North Virginia, that's US-west-1*
    - **⚠️`NOTE:ALERT!`⚠️:** *Also Confirm that The Selected Region Has A `Default VPC` You're Confident Has Internet Connection*
    - **⚠️`NOTE:ALERT!`⚠️:** *The Default Terraform Provider Region Defined In The Config Is **`Ohio(US-west-2)`***
- Confirm you're still logged into the `Jenkins-CI` Server via `SSH`
- Run the following commands to deploy the `EKS Cluster` in the `Jenkins-CI`
- **NOTE:** *You Can As Well Deploy The Cluster Using Terraform From Your Local System*

```bash
# Clone your project reporisoty
git clone https://github.com/Dappyplay4u/microservice-cicd.git

# cd and checkout into the DevSecOps project branch
cd \microservice-cicd\eks-cluster-ec2

# Deploy EKS Environment
terraform init
terraform plan
terraform apply --auto-approve
```
- Give it about `10 MINUTES` for the cluster creation to complete
- Then `Duplicate or Open` a New Console `Tab` and `Switch` to the `Ohio(us-west-2) Region`
- Navigate to `EKS` and confirm that your Cluster was created successfully with the name `EKS_Cluster`
- Also confirm there's no issue regarding your Terraform execution
![EKS Cluster](<eks cluster successful.png>)

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
    --region us-west-2 \
    --cluster minecraft-EKS-Cluster \
    --approve
```

#### 2D) Update/Get Cluster Credential: 
- Run this command from the `Jenkins-CI` instance
```bash
aws eks update-kubeconfig --name <clustername> --region <region>
```

#### 2E) Create Your Test and Prod Environment Namespaces
- Run this command from the `Jenkins-CI` instance
```bash
kubectl create ns test-env
kubectl create ns prod-env
kubectl get ns
```

#### 2F) Update the EKS Cluster Security Group (Add A NodePort and Frontend Port)
- Navigate to `EC2`
  - Select any of the `Cluster Worker Nodes`
  - Click on `Security`
  - Click on the `EKS Cluster Security Group ID`
  - Click on `Edit Inbound Rules`
  - Click on `Add Rule`
  - Port Number: `30000-32767`, `80`, `22` Source: `0.0.0.0/0`
  - Click on `SAVE`
![securitygroup](sec_group_nodeport.png)


#### 2G) Slack
- Go to the bellow Workspace and create a Private Slack Channel and name it "yourfirstname-jenkins-cicd-pipeline-alerts"
 - slack Link: https://join.slack.com/t/jjtechtowerba-zuj7343/shared_invite/zt-24mgawshy-EhixQsRyVuCo8UD~AbhQYQ
  - You can either join through the browser or your local Slack App
Create a Private Channel using the naming convention YOUR_INITIAL--multi-microservices-alerts
  - NOTE: (The Channel Name Must Be Unique, meaning it must be available for use)
Visibility: Select Private
Click on the Channel Drop Down and select Integrations and Click on Add an App
  - Search for Jenkins and Click on View
Click on Configuration/Install and Click Add to Slack
On Post to Channel: Click the Drop Down and select your channel above YOUR_INITIAL-multi-microservices-alerts
  - Click Add Jenkins CI Integration
  - Scrol Down and Click SAVE SETTINGS/CONFIGURATIONS
  - Leave this page open

![Slack channel](slack-multi-microservices-project.png)

#### 3) Metrics on EKS Stack
🧰 Prometheus Installation and Architecture

![prometheus architecture](prometheus-architecture.gif)

🧰 Step 1: Install kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

🚀 Step 2: Deploy the chart into a new namespace "monitoring"
kubectl create ns monitoring

helm install monitoring prometheus-community/kube-prometheus-stack \
-n monitoring \
-f ./custom_kube_prometheus_stack.yml

✅ Step 3: Verify the Installation
kubectl get all -n monitoring
Prometheus UI:
kubectl port-forward service/prometheus-operated -n monitoring 9090:9090
NOTE: If you are using an EC2 Instance or Cloud VM, you need to pass --address 0.0.0.0 to the above command. Then you can access the UI on instance-ip:port


#### 3) Monitoring

🧰 Grafana UI: password is prom-operator
kubectl port-forward service/monitoring-grafana -n monitoring 8080:80
Alertmanager UI:
kubectl port-forward service/alertmanager-operated -n monitoring 9093:9093


#### 🚀 Metrics and Monitoring on  a seprate EC2 (External Prometheus Scraping Kubernetes Metrics)

[Kubernetes Cluster]
    |
    └── kubelet / node-exporter / cAdvisor / kube-state-metrics / app metrics
           ↓
[Metrics exposed via NodePort or Ingress]
           ↓
[Prometheus on EC2] ←────── Securely scrapes these metrics over public IP or private networking

🧰 Step-by-Step Setup
🔹 1. Deploy Metrics Exporters Inside Kubernetes
Recommended: Use the kube-prometheus-stack, which bundles:

kube-state-metrics

node-exporter

Prometheus

Alertmanager

Grafana

📦 Install via Helm:
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install monitoring prometheus-community/kube-prometheus-stack \
-n monitoring \
-f ./eks-cluster-ec2/node_exporter.yml

🔹 2. Expose Metrics Outside the Cluster
To allow Prometheus on EC2 to access metrics, expose the Prometheus service.

✅ Option A: NodePort (Quick Setup)

node_exporter.yml

🌐 Access from EC2:

http://<k8s-node-external-ip>:30090/metrics

✅ Ensure the Kubernetes node’s security group allows inbound access from the EC2 IP on port 30090.

🔐 Option B: Ingress (Recommended for TLS + DNS)
Use this for secure HTTPS access via a DNS name:

/eks-cluster-ec2/prometheus-ingress.yml

🌐 Access from EC2:

http://prometheus.mycluster.mydomain.com/metrics
⚠️ Recommended with TLS via cert-manager, and protected with Basic Auth or mTLS.

🔹 3. Configure Prometheus on EC2 to Scrape K8s Metrics
Edit /etc/prometheus/prometheus.yml (or your custom config path):

scrape_configs:
  - job_name: 'k8s-metrics'
    metrics_path: /metrics
    static_configs:
      - targets:
          - <k8s-node-ip>:30090                 # NodePort target
          # OR
          - prometheus.mycluster.mydomain.com   # Ingress target
🌀 Restart Prometheus on EC2:

sudo systemctl restart prometheus
# or
docker restart prometheus  # if using Docker

🔹 4. Security Best Practices (Highly Recommended)
✅ Use HTTPS via cert-manager for Ingress

🔐 Restrict access to NodePort via EC2 IP allowlist in security group

🔐 Add Basic Authentication or mTLS to your Ingress controller

🔒 Keep EC2’s Prometheus instance in a VPC with restricted egress if possible

🧪 5. Test Connectivity from EC2
curl http://<k8s-node-ip>:30090/metrics
# OR
curl https://prometheus.mycluster.mydomain.com/metrics

✅ If metrics appear in response, Prometheus scraping is working!


#### 🚀📊 How Grafana Gets Metrics
Grafana doesn’t collect metrics by itself — it connects to a data source like Prometheus, InfluxDB, or others.

In this setup:

[EKS Cluster] → [Prometheus on EC2] → [Grafana on another EC2 instance]
Prometheus scrapes metrics from EKS (via NodePort or Ingress).

Grafana connects to Prometheus over HTTP or HTTPS using its public/private IP or DNS name.

Grafana uses PromQL queries to visualize the metrics Prometheus has stored.

🛠 Configuration Steps (EC2 → EC2)
✅ 1. Ensure Prometheus is Exposed to Grafana
Let’s say your Prometheus EC2 public IP is 54.123.45.67 and it's listening on port 9090.

You should:

Open port 9090 on Prometheus EC2 security group for Grafana EC2's IP.

Test from Grafana EC2:

curl http://54.123.45.67:9090/metrics
If this works — Prometheus is reachable.

✅ 2. Add Prometheus as a Data Source in Grafana
Option A: Use Grafana Web UI
Open your Grafana UI (e.g., http://<grafana-ec2-ip>:3000)

Go to ⚙️ Configuration → Data Sources

Click Add data source

Select Prometheus

Enter:

URL: http://54.123.45.67:9090

(Optional) Auth or TLS if Prometheus is secured

Click Save & Test
