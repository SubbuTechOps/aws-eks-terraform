pipeline {
    agent any

    environment {
        VAULT_URL = '' // Vault server URL
    }

    stages {
	stage("Fetch Credentials from Vault") {
	    steps {
	        script {
	            withCredentials([
	                string(credentialsId: 'VAULT_URL', variable: 'VAULT_URL'),
	                string(credentialsId: 'vault-role-id', variable: 'VAULT_ROLE_ID'),
	                string(credentialsId: 'vault-secret-id', variable: 'VAULT_SECRET_ID')
	            ]) {
	                echo "Fetching GitHub and AWS credentials from Vault..."
	
	                // Fetch secrets with error handling
	                sh '''
	                # Set Vault server URL
	                export VAULT_ADDR="${VAULT_URL}"
	
	                # Log into Vault using AppRole
	                echo "Logging into Vault..."
	                VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id=${VAULT_ROLE_ID} secret_id=${VAULT_SECRET_ID} || { echo "Vault login failed"; exit 1; })
	                export VAULT_TOKEN=$VAULT_TOKEN
	
	                # Fetch GitHub token
	                echo "Fetching GitHub Token..."
	                GIT_TOKEN=$(vault kv get -field=pat secret/github || { echo "Failed to fetch GitHub token"; exit 1; })
	
	                # Fetch AWS credentials
	                echo "Fetching AWS Credentials..."
	                AWS_ACCESS_KEY_ID=$(vault kv get -field=aws_access_key_id aws/terraform-project || { echo "Failed to fetch AWS Access Key ID"; exit 1; })
	                AWS_SECRET_ACCESS_KEY=$(vault kv get -field=aws_secret_access_key aws/terraform-project || { echo "Failed to fetch AWS Secret Access Key"; exit 1; })
	
	                # Export credentials to environment variables
	                echo "Exporting credentials to environment..."
	                echo "export GIT_TOKEN=${GIT_TOKEN}" >> vault_env.sh
	                echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> vault_env.sh
	                echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> vault_env.sh
	                '''
	
	                // Load credentials into environment
	                sh '''
	                echo "Loading credentials into environment..."
	                . ${WORKSPACE}/vault_env.sh
	                echo "Credentials loaded successfully."
	                '''
	            }
	        }
	    }
	}
	       
        stage("Checkout Source Code") {
            steps {
                script {
                    echo "Checking out source code from GitHub..."
                    sh '''
                    git clone https://${GIT_TOKEN}@github.com/SubbuTechOps/aws-eks-terraform.git
                    cd aws-eks-terraform
                    '''
                }
            }
        }

        stage("Install Terraform") {
            steps {
                echo "Installing Terraform..."
                sh '''
                wget -q -O terraform.zip https://releases.hashicorp.com/terraform/1.3.4/terraform_1.3.4_linux_amd64.zip
                unzip -o terraform.zip
                rm -f terraform.zip
                chmod +x terraform
                ./terraform --version
                '''
            }
        }
        
        stage("Terraform Init") {
            steps {
                echo "Initializing Terraform..."
                sh '''
                export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                cd aws-eks-terraform
                . ${WORKSPACE}/vault_env.sh
        
                # Debugging to verify credentials
                echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
                echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
        
                ../terraform init
                '''
            }
        }
        
        stage("Terraform Plan and Apply") {
            steps {
                echo "Running Terraform Plan and Apply..."
                sh '''
                # Load AWS credentials
                . ${WORKSPACE}/vault_env.sh
        
                # Verify credentials
                echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
                echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
        
                # Run Terraform
                cd aws-eks-terraform
                ../terraform plan -out=tfplan
		echo "Running Terraform Apply..."
                ../terraform apply -auto-approve tfplan
		echo "Terraform Apply completed successfully."
                '''
            }
        }
    stage("Update Kubeconfig and Verify") {
        steps {
            echo "Updating kubeconfig using AWS credentials from Vault..."
            sh '''
            # Step 1: Load AWS credentials
            echo "Loading AWS credentials..."
            . ${WORKSPACE}/vault_env.sh
    
            # Step 2: Verify AWS credentials
            aws sts get-caller-identity || { echo "Invalid AWS credentials"; exit 1; }
    
            # Step 3: Retrieve EKS cluster name
            echo "Retrieving EKS cluster name..."
            CLUSTER_NAME=$(aws eks list-clusters --region us-east-1 --query 'clusters[0]' --output text)
            if [ -z "$CLUSTER_NAME" ]; then
                echo "No EKS cluster found. Exiting..."
                exit 1
            fi
            echo "EKS Cluster Name: $CLUSTER_NAME"
    
            # Step 4: Update Kubeconfig in Jenkins home directory
            echo "Updating kubeconfig..."
            KUBE_CONFIG_PATH="/var/lib/jenkins/.kube/config"
            mkdir -p /var/lib/jenkins/.kube
            aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-1 --kubeconfig $KUBE_CONFIG_PATH
    
            # Step 5: Set permissions for Jenkins user
            chown jenkins:jenkins $KUBE_CONFIG_PATH
            chmod 600 $KUBE_CONFIG_PATH
    
            # Step 6: Verify Kubernetes connectivity
            export KUBECONFIG=$KUBE_CONFIG_PATH
            echo "Verifying Kubernetes connectivity..."
            kubectl get nodes
	    kubectl get pods --all-namespaces
            '''
        }
    }

    
	stage("Prompt for Terraform Destroy") {
	    steps {
	        script {
	            def userInput = input(
	                id: 'ConfirmDestroy',
	                message: 'Do you want to destroy the infrastructure?',
	                parameters: [
	                    choice(name: 'PROCEED', choices: ['Yes', 'No'], description: 'Select Yes to destroy or No to skip.')
	                ]
	            )
	            if (userInput == 'Yes') {
	                echo "User confirmed to proceed with destroy."
	                env.PROCEED_DESTROY = "true"
	            } else {
	                echo "User chose not to destroy. Skipping Terraform Destroy stage."
	                env.PROCEED_DESTROY = "false"
	                currentBuild.result = 'SUCCESS' // Explicitly mark the build as successful
	                return // Gracefully exit the stage
	            }
	        }
	    }
	}
	
	stage("Terraform Destroy") {
	    when {
	        expression { return env.PROCEED_DESTROY == "true" }
	    }
	    steps {
	        echo "Running Terraform Destroy..."
	        sh '''
	        # Load AWS credentials
	        . ${WORKSPACE}/vault_env.sh
	
	        # Run Terraform destroy
	        cd aws-eks-terraform
	        ../terraform destroy -auto-approve
	        '''
	    }
	}
        
    }

    post {
        success {
            echo "Pipeline executed successfully!"
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
        always {
            cleanWs()
            echo "Workspace cleaned successfully."
        }
    }
}
