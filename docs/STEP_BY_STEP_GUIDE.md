# 🚀 Complete Step-by-Step Guide: Jenkins + Docker CI/CD on AWS EC2 (Free Tier)

This guide is specifically written for students and engineers using the **AWS Free Tier (`t2.micro`)**. Follow these exact steps to launch and automate your pipeline.

---

## 📌 Architecture Overview

```
[ Developer ]
      │ (git push)
      ▼
 [ GitHub ] ──── (GitHub Webhook: port 8080) ────► [ AWS EC2 (t2.micro) ]
                                                   │
                                                   ├── 1. Jenkins Pipeline triggers
                                                   ├── 2. Jest Unit Tests run
                                                   ├── 3. Docker Image builds
                                                   ├── 4. Image pushes to Docker Hub
                                                   ├── 5. Deploy container on port 3000
                                                   └── 6. Health check & Verification
```

---

## 🟢 Step 1: Launch an AWS EC2 Free Tier Instance

1. Log in to the [AWS Management Console](https://aws.amazon.com/console/).
2. Navigate to **EC2** &rarr; click **Launch Instance**.
3. Configure the instance:
   - **Name**: `Jenkins-CI-CD-Server`
   - **AMI (Amazon Machine Image)**: `Ubuntu Server 24.04 LTS` or `Ubuntu 22.04 LTS` (Free tier eligible).
   - **Instance Type**: `t2.micro` (1 vCPU, 1 GiB Memory, Free tier eligible).
   - **Key pair**: Create a new key pair or choose an existing `.pem` key pair (e.g., `devops-key.pem`).
4. **Network Settings (Security Group)**:
   Click **Edit** and configure these inbound firewall rules:
   
   | Type | Protocol | Port Range | Source | Purpose |
   | :--- | :--- | :--- | :--- | :--- |
   | **SSH** | TCP | `22` | `My IP` | Secure terminal access |
   | **Custom TCP** | TCP | `8080` | `0.0.0.0/0` | Jenkins Web UI & GitHub Webhook |
   | **Custom TCP** | TCP | `3000` | `0.0.0.0/0` | Deployed Web Application |
   | **HTTP** | TCP | `80` | `0.0.0.0/0` | Web Traffic (Optional / Nginx) |

5. **Storage**: Leave default (8 GiB gp3) or set to `15 GiB` (Free tier gives up to 30 GiB of EBS storage free).
6. Click **Launch Instance**.

---

## 🟢 Step 2: Connect to EC2 & Run the 1-Click Provisioning Script

1. Open your terminal on your local computer and connect to your EC2 instance:
   ```bash
   chmod 400 devops-key.pem
   ssh -i devops-key.pem ubuntu@<YOUR-EC2-PUBLIC-IP>
   ```

2. Clone this repository onto your EC2 server:
   ```bash
   git clone https://github.com/<your-username>/<your-repo-name>.git
   cd "<your-repo-name>"
   ```

3. Run the automated provisioning script:
   ```bash
   chmod +x scripts/*.sh
   ./scripts/setup-jenkins-ec2.sh
   ```

> [!IMPORTANT]
> **Why the 2GB Swap Memory in the script is vital for AWS Free Tier:**
> An AWS `t2.micro` instance has only 1 GB of RAM. Running Jenkins (Java JVM) and building Docker containers simultaneously requires ~1.5 GB. Without Swap space, the Linux kernel's **OOM Killer (Out-of-Memory Killer)** will abruptly kill Jenkins during builds.
> Our script automatically creates a **2 GB Swap file**, making Jenkins rock-solid on the Free Tier!

4. Copy the **Initial Admin Password** output at the end of the script:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

---

## 🟢 Step 3: Complete Jenkins Initial Setup

1. Open your web browser and go to:
   ```text
   http://<YOUR-EC2-PUBLIC-IP>:8080
   ```
2. Paste the Initial Admin Password copied from Step 2.
3. Click **"Install suggested plugins"** and wait for the installer to finish.
4. Create your **First Admin User** (e.g., username: `admin`, password: `<your-password>`).
5. Keep the Jenkins URL as `http://<YOUR-EC2-PUBLIC-IP>:8080` and click **Save and Finish**.

---

## 🟢 Step 4: Configure Docker Hub Credentials in Jenkins

1. Create a free account at [Docker Hub](https://hub.docker.com) if you do not have one.
2. Generate an Access Token:
   - Go to Docker Hub &rarr; **Account Settings** &rarr; **Security** &rarr; **New Access Token**.
   - Description: `jenkins-cicd-token` &rarr; Generate & copy the token.
3. Add credentials into Jenkins:
   - In Jenkins, go to **Manage Jenkins** &rarr; **Credentials** &rarr; **System** &rarr; **Global credentials (unrestricted)**.
   - Click **Add Credentials**.
   - **Kind**: `Username with password`
   - **Scope**: `Global`
   - **Username**: Your Docker Hub username
   - **Password**: Your Docker Hub Access Token (or password)
   - **ID**: `dockerhub-credentials` *(Must match the ID in the Jenkinsfile)*
   - Click **Create**.

---

## 🟢 Step 5: Create your Jenkins CI/CD Pipeline Job

1. On the Jenkins home screen, click **New Item**.
2. Enter item name: `devops-cicd-pipeline`.
3. Select **Pipeline** and click **OK**.
4. Scroll down to the **Build Triggers** section:
   - Check ✅ **GitHub hook trigger for GITScm polling**.
5. Scroll down to the **Pipeline** section:
   - **Definition**: Select `Pipeline script from SCM`.
   - **SCM**: Select `Git`.
   - **Repository URL**: `https://github.com/<your-username>/<your-repo-name>.git`.
   - **Branch Specifier**: `*/main` (or `*/master`).
   - **Script Path**: `Jenkinsfile`.
6. Click **Save**.

---

## 🟢 Step 6: Configure GitHub Webhook for Automated Triggers

To make Jenkins trigger a build automatically on every `git push`:

1. Go to your GitHub repository in your web browser.
2. Click **Settings** &rarr; **Webhooks** &rarr; **Add webhook**.
3. Configure the fields:
   - **Payload URL**: `http://<YOUR-EC2-PUBLIC-IP>:8080/github-webhook/` *(Notice the trailing slash!)*
   - **Content type**: `application/json`
   - **Secret**: *(Leave empty for now)*
   - **Which events would you like to trigger this webhook?**: Select **"Just the push event"**.
   - Check ✅ **Active**.
4. Click **Add webhook**.
5. You should see a green checkmark indicating GitHub successfully pinged Jenkins!

---

## 🟢 Step 7: Trigger and Verify the Pipeline

1. In Jenkins, click **Build Now** to run the initial pipeline manually.
2. Watch each stage pass with a green check:
   - ✅ **Checkout SCM**
   - ✅ **Test & Quality Checks** (`npm ci`, `npm test`)
   - ✅ **Build Docker Image**
   - ✅ **Push to Docker Hub**
   - ✅ **Deploy Container**
   - ✅ **Post-Deployment Verification** (`/health` endpoint)
3. Open your browser and view your deployed application live:
   ```text
   http://<YOUR-EC2-PUBLIC-IP>:3000
   ```
4. Now test automated CD:
   - Make a change in `src/public/index.html` locally.
   - Run `git commit -am "feat: update dashboard"` and `git push origin main`.
   - Watch GitHub trigger Jenkins via webhook and deploy the update with zero downtime!

---

## 🟢 Step 8: (Optional) Setup Email Notifications

To receive email alerts on build success or failure:
1. In Jenkins: **Manage Jenkins** &rarr; **Plugins** &rarr; install **Email Extension Plugin**.
2. Go to **Manage Jenkins** &rarr; **System** &rarr; scroll to **Extended E-mail Notification**:
   - **SMTP server**: `smtp.gmail.com`
   - **SMTP Port**: `465` (or `587`)
   - **Credentials**: Add your Gmail and a generated **Google App Password** (from Google Account &rarr; Security &rarr; App Passwords).
   - Check ✅ **Use SSL**.
3. Uncomment the `emailext` block in `Jenkinsfile`.
