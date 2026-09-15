# 🚀 Production-Ready End-to-End CI/CD Pipeline

[![CI/CD](https://img.shields.io/badge/CI%2FCD-Jenkins-blue?logo=jenkins)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Container-Docker-2496ED?logo=docker)](https://www.docker.com/)
[![Cloud](https://img.shields.io/badge/Cloud-AWS%20EC2-FF9900?logo=amazon-aws)](https://aws.amazon.com/ec2/)
[![OS](https://img.shields.io/badge/OS-Ubuntu%20Linux-E95420?logo=ubuntu)](https://ubuntu.com/)
[![Runtime](https://img.shields.io/badge/Node.js-v20-339933?logo=node.js)](https://nodejs.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An enterprise-grade, automated CI/CD pipeline built for **Git, Jenkins, Docker, and AWS EC2 (Free Tier)**. It automatically tests code, builds lightweight multi-stage container images, pushes them to Docker Hub, and executes zero-downtime rolling container deployments on AWS EC2 upon every Git commit.

---

## 🏗️ Architecture & Pipeline Flow

```text
  Developer
      │
      │ 1. git push
      ▼
┌─────────────┐       2. Webhook (port 8080)       ┌───────────────────────────────┐
│   GitHub    │ ─────────────────────────────────► │    AWS EC2 (Ubuntu Linux)     │
└─────────────┘                                    │                               │
                                                   │  ┌─────────────────────────┐  │
                                                   │  │    Jenkins Pipeline     │  │
                                                   │  │                         │  │
                                                   │  │  1. SCM Checkout        │  │
                                                   │  │  2. Unit Tests (Jest)   │  │
                                                   │  │  3. Docker Image Build  │  │
                                                   │  │  4. Push to Docker Hub  │  │
                                                   │  │  5. Deploy Container    │  │
                                                   │  │  6. Health Verification │  │
                                                   │  └────────────┬────────────┘  │
                                                   │               │               │
                                                   │               ▼               │
                                                   │  ┌─────────────────────────┐  │
                                                   │  │ Docker App (port 3000)  │  │
                                                   │  │ Live Dashboard & API    │  │
                                                   │  └─────────────────────────┘  │
                                                   └───────────────────────────────┘
```

---

## ✨ Features & Highlights

- **AWS Free Tier Optimized (`t2.micro`)**: Includes automated Linux swap-space setup so Jenkins and Docker never crash from Linux OOM killer on 1GB RAM instances.
- **Declarative Jenkinsfile**: Pipeline-as-code featuring timeout guards, workspace cleanup, log rotation, and credentials masking.
- **Multi-Stage Docker Image**: Strips build tools, uses Alpine Linux base, and executes as non-root user (`USER node`) for hardened security.
- **Zero-Downtime Deployment**: Container replacement script `scripts/deploy.sh` with automatic image pulling and HTTP smoke test verification.
- **Interactive Live Dashboard**: Built-in dark-mode monitoring dashboard at `http://<EC2-IP>:3000` with live system metrics and health testing.
- **100% Interview Ready**: Includes a complete DevOps interview guide with answers to 15 real interview questions.

---

## 📁 Repository Structure

```text
├── app/ & src/               # Express demo application & dashboard
│   ├── public/index.html     # Modern dark-mode dashboard UI
│   ├── app.js                # Routes (/health, /api/info)
│   └── server.js             # Graceful shutdown & server listener
├── test/
│   └── app.test.js           # Automated smoke & integration tests (Jest)
├── scripts/
│   ├── setup-swap.sh         # Linux Swap memory creator for Free Tier
│   ├── setup-jenkins-ec2.sh  # 1-click EC2 setup (Docker, Java, Jenkins)
│   └── deploy.sh             # Zero-downtime container deployment script
├── docs/
│   ├── STEP_BY_STEP_GUIDE.md # Detailed AWS & Jenkins step-by-step setup guide
│   └── INTERVIEW_GUIDE.md    # Top 15 DevOps interview questions & answers
├── Dockerfile                # Multi-stage production container definition
├── docker-compose.yml        # Local orchestration file
├── Jenkinsfile               # Declarative Jenkins CI/CD pipeline
└── package.json              # Node.js dependencies & test scripts
```

---

## ⚡ Quick Start (Run Locally with Docker)

### 1. Run with Docker Compose
```bash
docker-compose up --build
```
Access the application dashboard at `http://localhost:3000`.

### 2. Run Tests
```bash
npm install
npm test
```

---

## ☁️ Deploying on AWS EC2 (Free Tier)

Read the comprehensive step-by-step guide in [docs/STEP_BY_STEP_GUIDE.md](docs/STEP_BY_STEP_GUIDE.md).

1. **Launch an AWS EC2 instance** (`t2.micro`, Ubuntu 24.04/22.04 LTS).
2. **Open Security Group ports**: `22` (SSH), `8080` (Jenkins/Webhook), `3000` (Web App).
3. **SSH into EC2 and run the 1-click setup script**:
   ```bash
   git clone <your-github-repo-url>
   cd <repo-folder>
   chmod +x scripts/*.sh
   ./scripts/setup-jenkins-ec2.sh
   ```
4. **Access Jenkins**: Open `http://<YOUR-EC2-PUBLIC-IP>:8080` and enter the initial admin password shown in the terminal.
5. **Add Docker Hub Credentials**: Create a credential in Jenkins with ID `dockerhub-credentials`.
6. **Set up GitHub Webhook**: Add payload URL `http://<YOUR-EC2-PUBLIC-IP>:8080/github-webhook/`.
7. **Commit & Push**: Watch the pipeline automatically build and deploy!


👤 Author:
GitHub:[https://github.com/Harshu9671]

## 📄 License
This project is open source and available under the [MIT License](LICENSE).
