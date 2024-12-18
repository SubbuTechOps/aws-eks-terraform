# Project Overview:
Effectively and securely managing infrastructure is essential for modern DevOps workflows. This guide will create an End-to-End Infrastructure-as-Code (IaC) pipeline to provision an AWS EKS cluster using Terraform. We will automate the pipeline with Jenkins and securely manage sensitive credentials using HashiCorp Vault.
### Please refer to the link below for complete information:
**@SubbuTechOps:** https://subbutechops.com/end-to-end-aws-eks-provisioning-with-terraform-jenkins-ci-cd-and-hashicorp-vault/
**@Medium:** https://medium.com/@subbareddysangham/end-to-end-aws-eks-provisioning-with-terraform-jenkins-ci-cd-and-hashicorp-vault-6caf11cb2d2c

# High-Level Architecture:
**1. Jenkins Server:**
- Deployed on an EC2 instance to manage CI/CD pipelines.
- Jenkins plugins installed: Terraform, Pipeline, AWS Credentials, and HashiCorp Vault.

**2. Vault Server:**
- Configured on a separate server to securely store and retrieve secrets (AWS and GitHub credentials).
- Secrets stored:
  - aws/terraform-project: Contains aws_access_key_id and aws_secret_access_key.
  - secret/github: Contains GitHub PAT (pat).

**3. Terraform Configurations:**
- Infrastructure as Code (IaC) to provision:
  - VPC, Subnets
  - EKS Cluster
  - Worker Nodes

**4. CI/CD Pipeline:**
Jenkins pipeline retrieves secrets from Vault and runs Terraform stages for EKS provisioning.

# Prerequisites:
**1. AWS Account:**
  - Ensure IAM permissions:
  - AmazonEKSFullAccess
  - AmazonEC2FullAccess
  - IAMFullAccess

**2. EC2 Server for Jenkins:**
- Jenkins installed and configured with required plugins.
- Vault credentials (vault-role-id, vault-secret-id, VAULT_URL) configured in Jenkins Credentials Store.
- Preinstall kubectl on the Jenkins Server:
  
![image](https://github.com/user-attachments/assets/bc7015ed-e622-40dc-b48b-9203b5a73211)


**3. HashiCorp Vault Server:**
- Vault configured with secrets:
  - aws/terraform-project → AWS credentials.
  - secret/github → GitHub PAT.
  - AppRole authentication configured (vault-role-id and vault-secret-id).

#### Best Practices:
**3.1 Automate Credential Renewal:**
- Since secret_id expires (the default TTL is 24 hours), consider automating its regeneration and updating Jenkins credentials programmatically.
Use Vault CLI or API scripts to refresh credentials periodically.

**3.2 Secure the Jenkins Secrets:**
- Ensure Jenkins credentials are properly encrypted and masked.
- Use Jenkins Secret Text credentials to avoid plain-text exposure in pipeline logs.

**3.3 Test Before Deploying:**
- Always validate the new role_id and secret_id using the Vault CLI before updating Jenkins.
- Please refer to the link below for complete information:
  https://blog.devops.dev/step-by-step-guide-using-hashicorp-vault-to-secure-aws-credentials-in-jenkins-ci-cd-pipelines-with-6a3971c63580

- Terraform Configurations Linear Process Diagram Outline:
  ![image](https://github.com/user-attachments/assets/0a4d04f8-f62d-40a1-8e8c-9602b0f34774)
  ![image](https://github.com/user-attachments/assets/81d3632d-6df3-4949-a896-ae7dead86dec)

# CI/CD Pipeline Execution Workflow
## Jenkins Pipeline Script Execution
Jenkins fetches credentials securely from HashiCorp Vault:
  - Vault AppRole authentication retrieves AWS and GitHub tokens.
  - Secrets are exported to environment variables (vault_env.sh).
## Pipeline Stages:
1. Fetch Credentials from Vault
2. Checkout Source Code
3. Install Terraform
4. Terraform Init: Initializes Terraform backend.
5. Terraform Plan and Apply: Provisions the VPC, subnets, and EKS cluster.
6. Update Kubeconfig and Verify:
   - Dynamically retrieves EKS cluster details using AWS CLI.
   - Updates kubeconfig for kubectl.
7. Prompt for Terraform Destroy: Ensures controlled teardown.
8. Terraform Destroy (Optional): Destroys infrastructure after confirmation.

# Post-Execution Verification:
### **1. AWS Console:**
- Navigate to EKS > Verify the cluster and node group creation.
  
### **2. CLI Commands:**
- Test Kubernetes connectivity:
```bash
kubectl get nodes
kubectl get pods --all-namespaces
  ```  

#### Note:
The Jenkins pipeline script dynamically updates the kubeconfig for the Jenkins user during pipeline execution, which allows access to the EKS cluster for CI/CD jobs. However, when a user manually logs into the Jenkins server (for example, the Ubuntu user), the kubeconfig must be configured explicitly. This is necessary because it is located in a different directory and is not shared between users.

#### Why This Happens?

**Jenkins Pipeline Context:**

- The pipeline uses the /var/lib/jenkins/.kube/config file, specifically created for the Jenkins user.
- Kubernetes commands (kubectl) executed by Jenkins are scoped to Jenkins' home directory (/var/lib/jenkins).

**Manual Login Context:**
- When you log in as ubuntu, the system looks for the kubeconfig in the default location for the ubuntu user, which is ~/.kube/config (i.e., /home/ubuntu/.kube/config).
- Since the pipeline kubeconfig is set for the Jenkins user, it is not automatically available for the ubuntu user.

### **3. Terraform State:**
- Verify Terraform state is stored in the backend or locally.

# Conclusion:
Bringing together AWS EKS, Terraform, Jenkins, and HashiCorp Vault might seem overwhelming at first, but breaking it into clear steps makes the process smooth and achievable.

 By automating infrastructure provisioning, streamlining CI/CD workflows, and managing secrets securely, you’ll create a robust, scalable, and secure Kubernetes environment.

This project not only enhances your DevOps skills but also demonstrates your ability to integrate modern tools effectively — a skill set essential for real-world production scenarios.

Start small, automate smart, and build confidence as you master the tools powering today’s cloud-native world! 🚀
