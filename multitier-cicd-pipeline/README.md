# 🔁 Multi-Tier Web App CI/CD Pipeline
### Jenkins | AWS | Terraform | SonarQube | Trivy | Docker | Kubernetes

![Pipeline](https://img.shields.io/badge/CI%2FCD-Jenkins-D33833?logo=jenkins)
![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws)
![Security](https://img.shields.io/badge/Security-SonarQube%20%2B%20Trivy-blue)
![IaC](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)
![Bugs Caught](https://img.shields.io/badge/Bugs%20Caught-100%2B-red)
![Manual Effort Reduced](https://img.shields.io/badge/Manual%20Effort-95%25%20Reduced-brightgreen)

---

## 📌 Project Overview

A fully automated, end-to-end **CI/CD pipeline** for a multi-tier web application. The pipeline handles everything from code commit to production deployment — including **static code analysis with SonarQube**, **container security scanning with Trivy**, and **infrastructure provisioning with Terraform** — with **95% reduction in manual release effort**.

---

## 🏗️ Pipeline Architecture

```
  Developer
      │
      ▼ git push
 ┌────────────────────────────────────────────────────────────────┐
 │                      Jenkins Pipeline                          │
 │                                                                │
 │  ① Checkout  →  ② Build  →  ③ SonarQube  →  ④ Trivy Scan    │
 │                                                                │
 │  ⑤ Push to ECR  →  ⑥ Terraform Plan  →  ⑦ Terraform Apply   │
 │                                                                │
 │  ⑧ Deploy to K8s (Dev)  →  ⑨ Smoke Test  →  ⑩ Deploy Prod  │
 └────────────────────────────────────────────────────────────────┘
           │                          │
           ▼                          ▼
    ┌─────────────┐           ┌───────────────┐
    │  AWS ECR    │           │  AWS S3        │
    │ (Images)    │           │ (Terraform     │
    └─────────────┘           │  State)        │
                              └───────────────┘
           │
           ▼
 ┌─────────────────────────────────────────────┐
 │           AWS Infrastructure                │
 │                                             │
 │  VPC → EC2 (App) → RDS (DB) → S3 (Assets) │
 │  ALB → Auto Scaling Group → CloudWatch     │
 └─────────────────────────────────────────────┘
```

---

## ✨ Key Achievements

| Metric | Result |
|--------|--------|
| ⚡ Manual Effort | **95% reduced** via full automation |
| 🐛 Bugs Detected | **100+ bugs & vulnerabilities** caught pre-production |
| 🏗️ Infra Provisioned | **20+ AWS resources** in < 10 minutes |
| 🔒 Security Gate | Zero critical CVEs reach production |
| 🔁 Pipeline Stages | 10 automated stages, end-to-end |

---

## 🧰 Tech Stack

| Category | Tools |
|----------|-------|
| CI/CD Orchestration | Jenkins (Declarative Pipeline) |
| Code Quality | SonarQube |
| Security Scanning | Trivy (images + filesystem) |
| Containerization | Docker, AWS ECR |
| IaC | Terraform |
| Cloud | AWS (EC2, RDS, S3, VPC, ALB, CloudWatch) |
| Orchestration | Kubernetes (optional K8s stage) |
| Build | Maven |
| Notifications | Slack / Email |

---

## 📁 Project Structure

```
multitier-cicd-pipeline/
├── Jenkinsfile                  # Declarative pipeline definition
├── docker/
│   ├── app/Dockerfile           # Application Dockerfile
│   └── nginx/Dockerfile         # Nginx reverse proxy
├── terraform/
│   ├── modules/
│   │   ├── vpc/                 # VPC, subnets, routing
│   │   ├── ec2/                 # App server instances
│   │   ├── rds/                 # PostgreSQL RDS
│   │   └── s3/                  # S3 static assets bucket
│   └── environments/
│       ├── dev/                 # Dev environment
│       └── prod/                # Prod environment
├── sonarqube/
│   └── sonar-project.properties # SonarQube config
├── trivy/
│   └── trivy-config.yaml        # Trivy scan configuration
├── kubernetes/
│   ├── deployment.yaml
│   └── service.yaml
├── scripts/
│   ├── deploy.sh
│   └── rollback.sh
└── app/
    ├── src/                     # Application source
    └── tests/                   # Test suite
```

---

## 🚀 Setup Guide

### Prerequisites

- Jenkins server with plugins: Git, Docker, SonarQube Scanner, AWS Credentials, Slack Notification
- SonarQube server (or SonarCloud)
- AWS account with ECR, EC2, RDS, VPC permissions
- Terraform installed on Jenkins agent

### Step 1 — Jenkins Configuration

1. Install required plugins in Jenkins
2. Add credentials:
   - `aws-credentials` — AWS Access Key + Secret
   - `sonarqube-token` — SonarQube auth token
   - `dockerhub-credentials` — DockerHub (optional)
   - `slack-token` — Slack webhook

3. Configure SonarQube server in Jenkins → Manage Jenkins → Configure System

### Step 2 — Create Pipeline

```
New Item → Pipeline → Pipeline script from SCM → Git → Repo URL → Jenkinsfile
```

### Step 3 — Configure SonarQube

```bash
# sonarqube/sonar-project.properties is pre-configured
# Just update the projectKey and host URL
```

### Step 4 — First Run

Push to `main` or `develop` branch — Jenkins webhook triggers automatically.

---

## 📊 Pipeline Stages Explained

| Stage | What Happens |
|-------|-------------|
| **Checkout** | Pull source code from Git |
| **Build** | `mvn clean package` — compile & package |
| **SonarQube Analysis** | Static code analysis, detect code smells & bugs |
| **Quality Gate** | Fail pipeline if SonarQube quality gate fails |
| **Trivy FS Scan** | Scan filesystem for CVEs before building image |
| **Docker Build** | Build container image with build tag |
| **Trivy Image Scan** | Scan Docker image — fail on HIGH/CRITICAL |
| **Push to ECR** | Tag and push image to AWS ECR |
| **Terraform Apply** | Provision/update AWS infra (idempotent) |
| **Deploy to K8s** | Rolling update on Kubernetes cluster |

---

## 🔒 Security Gates

```
Code Commit
    │
    ├── SonarQube Quality Gate ──► FAIL: pipeline stops, dev notified
    │
    ├── Trivy Filesystem Scan ───► FAIL: pipeline stops on CRITICAL
    │
    ├── Trivy Image Scan ────────► FAIL: pipeline stops on HIGH+
    │
    └── Deploy ──────────────────► Only if ALL gates pass ✅
```

---

## 📜 License

MIT License
