# ☸️ Kubernetes Cluster Automation
### AWS | kops | Terraform | Prometheus | Grafana | Helm

![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?logo=kubernetes)
![AWS](https://img.shields.io/badge/AWS-EKS%2FkOps-FF9900?logo=amazon-aws)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)
![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-F46800)

---

## 📌 Project Overview

Fully automated provisioning of a **highly available Kubernetes cluster** on AWS using **kops** and **Terraform**. The cluster features auto-scaling, production-grade monitoring via **Prometheus & Grafana**, and zero-touch infrastructure management.

---

## 🏗️ Architecture

```
                    ┌──────────────────────────────────────┐
                    │            Route 53 (DNS)             │
                    └──────────────┬───────────────────────┘
                                   │
                    ┌──────────────▼───────────────────────┐
                    │          kops State (S3)              │
                    │     cluster config & state store     │
                    └──────────────┬───────────────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          ▼                        ▼                        ▼
  ┌──────────────┐       ┌──────────────────┐      ┌──────────────┐
  │  Master Node │       │  Master Node     │      │  Master Node │
  │  (AZ: us-   │       │  (AZ: us-        │      │  (AZ: us-    │
  │  east-1a)   │       │  east-1b)        │      │  east-1c)    │
  └──────┬───────┘       └──────┬───────────┘      └──────┬───────┘
         │                      │                          │
         └──────────────────────┼──────────────────────────┘
                                │
              ┌─────────────────▼─────────────────┐
              │         Worker Node Pool           │
              │    (Auto-Scaling Group: 3-10)      │
              │  ┌──────────┐  ┌──────────────┐   │
              │  │  Worker  │  │   Worker     │   │
              │  │  Node 1  │  │   Node 2     │   │
              │  └──────────┘  └──────────────┘   │
              └─────────────────┬─────────────────┘
                                │
              ┌─────────────────▼─────────────────┐
              │           Monitoring Stack         │
              │   Prometheus (metrics collection)  │
              │   Grafana    (dashboards)          │
              │   AlertManager (alerts)            │
              └───────────────────────────────────┘
```

---

## ✨ Key Achievements

| Feature | Detail |
|---------|--------|
| ☁️ Cluster HA | 3 master nodes across 3 AZs |
| 🔄 Auto-Scaling | Node autoscaler (3–10 nodes) |
| 📊 Monitoring | Prometheus + Grafana via Helm |
| 🛡️ Security | RBAC, network policies, IAM roles |
| ⚙️ Automation | Full provisioning in < 15 minutes |

---

## 🧰 Tech Stack

| Category | Tools |
|----------|-------|
| Cloud | AWS (EC2, VPC, Route53, S3, IAM) |
| Cluster Provisioning | kops, Terraform |
| Package Management | Helm |
| Monitoring | Prometheus, Grafana, AlertManager |
| Autoscaling | Cluster Autoscaler, HPA |
| DNS | Route 53 |

---

## 📁 Project Structure

```
kubernetes-cluster-automation/
├── terraform/
│   ├── modules/
│   │   ├── networking/        # VPC, Subnets, Route Tables
│   │   ├── iam/               # IAM roles & policies for kops
│   │   └── kops-cluster/      # kops state bucket & DNS
│   └── environments/
│       ├── dev/               # Dev cluster tfvars
│       └── prod/              # Prod cluster tfvars
├── kops/
│   ├── cluster.yaml           # kops cluster spec
│   └── instancegroups/        # Instance group configs
├── monitoring/
│   ├── prometheus/
│   │   ├── values.yaml        # Prometheus Helm values
│   │   └── alerting-rules.yaml
│   └── grafana/
│       ├── values.yaml        # Grafana Helm values
│       └── dashboards/
├── scripts/
│   ├── create-cluster.sh      # Full cluster bootstrap
│   ├── destroy-cluster.sh     # Teardown script
│   └── update-cluster.sh      # Rolling update script
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with admin permissions
- `kops`, `kubectl`, `terraform`, `helm` installed
- A registered domain in Route 53 (e.g., `k8s.yourdomain.com`)

### Step 1 — Provision Base Infrastructure

```bash
cd terraform/environments/prod
terraform init
terraform apply -var-file="prod.tfvars"
```

This creates:
- S3 bucket for kops state store
- IAM roles for kops
- VPC, subnets, route tables
- Route 53 hosted zone

### Step 2 — Bootstrap the Cluster

```bash
# Set environment variables
export KOPS_STATE_STORE=s3://your-kops-state-bucket
export CLUSTER_NAME=prod.k8s.yourdomain.com

# Run the bootstrap script
chmod +x scripts/create-cluster.sh
./scripts/create-cluster.sh
```

### Step 3 — Deploy Monitoring Stack

```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f monitoring/prometheus/values.yaml

# Verify
kubectl get pods -n monitoring
```

### Step 4 — Access Grafana

```bash
# Get Grafana admin password
kubectl get secret --namespace monitoring grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode

# Port-forward to access locally
kubectl port-forward --namespace monitoring svc/grafana 3000:80

# Open http://localhost:3000 (admin / <password above>)
```

---

## 🔄 Cluster Autoscaling

The Cluster Autoscaler is pre-configured via Helm:

```bash
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=$CLUSTER_NAME \
  --set awsRegion=us-east-1 \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<ROLE_ARN>
```

---

## 🔒 Security

- **RBAC** enabled cluster-wide
- **Network Policies** restrict pod-to-pod communication
- **IAM Roles for Service Accounts (IRSA)** — no static credentials
- **etcd** encryption at rest
- **API server** access restricted via security groups

---

## 📜 License

MIT License
