#!/usr/bin/env bash
# ==============================================================================
# Automated Provisioning Script for Jenkins & Docker on Ubuntu (AWS EC2)
# Optimized for AWS Free Tier (Ubuntu 22.04 / 24.04 LTS)
# ==============================================================================

set -euo pipefail

echo "======================================================================"
echo "🚀 Starting Jenkins & Docker Automated Setup on AWS EC2"
echo "======================================================================"

# 1. Update system package index
echo "==> Updating package indices..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git gnupg lsb-release ca-certificates apt-transport-https

# 2. Setup 2GB Swap Memory (Crucial for AWS t2.micro Free Tier)
echo "==> Checking and setting up Swap memory..."
if free -h | grep -q "Swap: *0B"; then
    echo "Creating 2GB swap file..."
    sudo fallocate -l 2G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
    fi
    sudo sysctl vm.swappiness=10
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    echo "Swap setup complete."
fi

# 3. Install Docker Engine
echo "==> Installing Docker Engine..."
if ! command -v docker &>/dev/null; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    # Add ubuntu user to docker group
    sudo usermod -aG docker ubuntu
    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

# 4. Install Java 17 (Required by Jenkins)
echo "==> Installing Java 17 OpenJDK..."
sudo apt-get install -y openjdk-17-jdk

# 5. Install Jenkins
echo "==> Adding Jenkins repository key & repository..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

# 6. Configure Permissions for Jenkins user
echo "==> Granting Docker permissions to Jenkins user..."
sudo usermod -aG docker jenkins

# Enable and start Jenkins
sudo systemctl enable jenkins
sudo systemctl restart jenkins

# Restart docker service so group modifications take effect
sudo systemctl restart docker

echo "======================================================================"
echo "🎉 Setup Completed Successfully!"
echo "======================================================================"
echo "Jenkins Service Status:"
sudo systemctl status jenkins --no-pager || true

echo ""
echo "----------------------------------------------------------------------"
echo "🔑 Initial Jenkins Admin Password:"
echo "----------------------------------------------------------------------"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || echo "Password file not created yet, please wait 30 seconds."
echo "----------------------------------------------------------------------"
echo "🌐 Access Jenkins in your browser:"
echo "   http://<YOUR-EC2-PUBLIC-IP>:8080"
echo "======================================================================"
