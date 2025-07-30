# ☁️ FortStack Internship – AWS Infrastructure Automation with Terraform, Ansible & Kubernetes

This repository contains the complete infrastructure setup and automation for deploying a Kubernetes-based application stack on AWS. The architecture is designed with security, automation, and GitOps principles in mind — provisioning the environment with **Terraform**, configuring instances with **Ansible**, and deploying applications with **ArgoCD**.

---

## 🧰 Tools & Technologies

- **Terraform**: Infrastructure provisioning (VPC, EC2, ALB, Security Groups, etc.)
- **Ansible**: Configuration management for EC2 instances
- **AWS**: Cloud provider
- **Kubernetes**: Container orchestration (via Minikube)
- **Helm**: Package manager for Kubernetes
- **ArgoCD**: GitOps continuous deployment tool
- **Docker**: Container runtime
- **NFS**: Network File System for persistent storage
- **NGINX**: Used for internal and external reverse proxies

---

## 🏗️ Architecture Overview

- ✅ **Bastion Host**:
  - Publicly accessible via SSH
  - Acts as a gateway to provision and manage private EC2 instances using Ansible
  - Hosts a reverse proxy to expose Kubernetes applications via ALB

- ✅ **Private Instances**:
  - Provisioned using Ansible
  - Run the following components:
    - Docker
    - NFS server
    - Minikube (single-node Kubernetes)
    - kubectl, Helm, ArgoCD
    - Node.js Todo App + MongoDB (deployed via Helm and ArgoCD)
  - Include a reverse proxy to expose NodePort services within the VPC

- ✅ **Networking**:
  - Custom VPC with public and private subnets
  - Security groups allowing controlled access
  - Internet-facing Application Load Balancer

---

## 📂 Repo Structure

```
FortStack-Internship/
├── ansible/                  # Ansible playbooks for provisioning private EC2 instancesinfra
├── modules/                  # Terraform modules and configuration for AWS 
├── scripts/                  # Helper scripts (e.g., for SSH or bootstrapping)
├── provider.tf               # This file is used to declare and configure the providers required by the Terraform configuration
├── backend.tf                # This file defines the backend configuration for storing Terraform's state file
├── main.tf                   # This file typically contains the primary infrastructure definitions,
├── README.md                 # Project overview and setup instructions
└── .gitignore
```

---

## 🚀 How It Works

1. **Terraform** provisions:
   - A custom VPC with subnets and route tables
   - A bastion host (public EC2 instance)
   - Private EC2 instances for Kubernetes cluster
   - Security Groups, IAM roles, and ALB

2. **Ansible** configures private instances **via bastion host** using `ansible_ssh_common_args` and provisions:
   - Docker and NFS server
   - Minikube + kubectl + Helm + ArgoCD
   - ArgoCD setup for GitOps deployment from [todo-list-gitops](https://github.com/AbdallahElaraby/Todo-List-nodejs-GitOps)

3. **Reverse Proxy Flow**:
   - Internal NGINX reverse proxy on the private instance forwards requests to NodePort service
   - External NGINX reverse proxy on the bastion forwards traffic to internal reverse proxy
   - Application Load Balancer exposes bastion reverse proxy to the internet

---

## ✅ Prerequisites

- AWS CLI configured
- Terraform installed
- SSH key pair for accessing EC2 instances

---

## 📦 Deployment Steps

```bash
# Step 1: Provision Infrastructure
terraform init
terraform apply

# Step 2: Configure Instances
cd ../ansible/
ansible-playbook -i ../inventory/hosts site.yaml
```

> Ensure that the GitOps deployment repo is correctly configured and accessible by ArgoCD.

---

## 🔐 Security Considerations

- Bastion host has the only public IP; all private instances are accessed through it.
- Security groups restrict access to required ports only.
- SSH access is protected by key authentication.

---

## 📝 License

MIT License  
© 2025 Abdallah Elaraby