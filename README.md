# Sagemaker AI Playground

## Overview

Welcome to the SageMaker AI Playground! 🤖 This repository provides a Terraform-based lab environment designed to deploy a robust AI research environment on AWS using **SageMaker AI** MLOps managed services. It separates the model hosting from the development environment for better production scalability and cost management.

This project was created to provide a ready-to-use "playground" for running generative AI workloads, specifically for cybersecurity research, with minimal manual setup. It deploys two core, decoupled resources:

1. A SageMaker Model Endpoint: A dedicated, GPU-accelerated (ml.g5.2xlarge) environment for hosting a large language model. It uses the Hugging Face TGI (Text Generation Inference) container to serve the model efficiently.

2. A SageMaker Notebook Instance: A cost-effective CPU instance (ml.t3.medium) that serves as your development environment. It comes pre-loaded with sample Jupyter notebooks that are automatically configured to interact with the model sagemaker endpoint.

The environment automatically deploys Cisco's Foundation-Sec-8B-Instruct, an open-weight, 8-billion parameter instruction-tuned language model specialized for cybersecurity applications.

## Key Features

* Managed GPU Inference: Deploys a powerful SageMaker Endpoint on a ml.g5.2xlarge instance, optimized for hosting LLMs without the need to manage servers, Docker, or NVIDIA drivers.  This resource is created via ```model_endpoint_instance.tf```.

* Hugging Face TGI Container: Uses the official Hugging Face Text Generation Inference container for high-performance, production-ready model serving.

* Pre-configured Notebook Environment: Launches a SageMaker Notebook instance that automatically clones a repository of cybersecurity use-case notebooks and configures them to use the deployed model endpoint.  The Sagemaker Jupyter notebook is created via ```notebook_instance.tf```.

* Scalable Architecture: By separating the notebook from the inference endpoint, you can stop the notebook to save costs while keeping the model available, or scale them independently.  You can also use the model endpoint with other applications instead of the Jupyter Notebook.  A sample python script (inference_query1.py) to run inference against the endpoint is included that uses Boto3 sagemaker client.

* Ready-to-Use Cyber Security Model: Automatically deploys the ```fdtn-ai/Foundation-Sec-8B-Instruct``` model from Hugging Face.  This represents your own private LLM model hosting and inference endpoint for Cyber Security use cases.


## Estimated Cost
**Disclaimer:** Deploying this playground will incur AWS charges. The costs are primarily driven by the SageMaker Endpoint and Notebook instances. You are billed for the time they are in the InService state.

This playground uses the following SageMaker instances by default. These can be customized in the Terraform files.

**Instance Information:**  Check the AWS Pricing page to confirm the latest pricing.
| Resource | Instance Type | vCPU | Memory (GiB) | GPU Memory (GiB) | Hourly Cost |
| :------- | :------: | -------: | -------: | -------: | -------: |  -------: |
| SageMaker Endpoint | ml.g5.2xlarge | 8 | 32 | 24 | $1.388 |
| SageMaker Notebook | ml.t3.medium | 2 | 4 | NA | $1.388 |


**To manage costs:**

Run the environment only when needed. Use terraform destroy to tear it down when not in use, and spin it up again later (note that any data on the instance will be lost unless you save it externally).

Consider using a smaller or cheaper instance if appropriate. AWS offers GPU instance types or spot instances at lower prices.

Monitor your AWS billing dashboard. Terraform outputs the instance ID and other info; you can use AWS Cost Explorer to see running costs in near-real time.

For a precise estimate tailored to your region and usage, use the AWS Pricing Calculator
 – input the EC2 instance type, EBS volume size, and duration you expect to run the lab to calculate the cost. Always remember to shut down the environment to stop charges.

## Requirements and Setup

## Screen Shots
[Some examples.](examples.md)

## Requirements and Setup

**Tested with:**

* Mac OS 13.4 or Ubuntu 22.04
* terraform 1.5.7
* AWS Service Limits: Ensure your AWS account can launch GPU instances in the chosen region. New accounts may need limit increases for GPU instance types.

**Clone this repository:**
```
git clone https://github.com/iknowjason/gpu-ai-playground
cd gpu-ai-playground
```

**Credentials Setup:**

Generate an IAM programmatic access key that has permissions to build resources in your AWS account.  Setup your .env to load these environment variables.  You can also use the direnv tool to hook into your shell and populate the .envrc.  Should look something like this in your .env or .envrc:

```
export AWS_ACCESS_KEY_ID="VALUE"
export AWS_SECRET_ACCESS_KEY="VALUE"
```

## Build and Destroy Resources

### Run terraform init
Change into the ```gpu-ai-playground``` working directory and type:

```
terraform init
```

### Run terraform plan or apply
```
terraform apply -auto-approve
```
or
```
terraform plan -out=run.plan
terraform apply run.plan
```

### Destroy resources
```
terraform destroy -auto-approve
```

### View terraform created resources
The lab has been created with important terraform outputs showing services, endpoints, IP addresses, and credentials.  To view them:
```
terraform output
```

# Details and Usage

## Accessing the Services

Once the deployment is complete, use the values from the ```terraform output``` command to access the services.

- n8n Admin Console: https://PUBLIC_IP

- Open WebUI Console: http://PUBLIC_IP:8443

- SSH Access: ssh -i ssh_key.pem ubuntu@PUBLIC_IP

## Monitoring the Bootstrap Process

The user_data.sh script handles the entire setup process. You can monitor its progress by SSHing into the instance and tailing the log file. The setup is complete when you see "End of bootstrap script".
```
# SSH into the server first
tail -f /var/log/cloud-init-output.log
```

You can also check the status of the PyTorch FastAPI server to ensure it's running:
```
sudo systemctl status foundation
```
Verify that the PyTorch FastAPI server is listening on port 9000:
```
sudo netstat -tulpn | grep 9000
```

## API Usage and Testing

The bootstrap process creates several test scripts in /home/ubuntu/test_inference_scripts/ on the server. Additionally, api_usage.txt provides instructions for remote testing.

### Remote Testing

### Open WebUI API Testing

Log in to the Open WebUI Console and create an API key in the settings.

Terraform creates a test script for you at ./test-inference-scripts/openwebui.sh. Edit this file and replace the CHANGE_BEFORE_FIRST_USING placeholder with your new API key.

Run the script from your local machine: bash ./test-inference-scripts/openwebui.sh

### PyTorch FastAPI API Testing

The API key is generated randomly during setup. SSH into the server to retrieve it:
```
grep FOUNDATION_API_KEY /home/ubuntu/foundation_server/.env
```
Terraform creates a test script at ./test-inference-scripts/pytorch.sh. Edit this file and replace the CHANGE_BEFORE_FIRST_USING placeholder with the key you just retrieved.

Run the script from your local machine: bash ./test-inference-scripts/pytorch.sh

### Example Terraform Output

After a successful deployment, your output will look similar to this:
```
n8n Admin Console
-------------
https://ec2-44-220-87-247.compute-1.amazonaws.com

Open WebUI Console
------------------
http://ec2-44-220-87-247.compute-1.amazonaws.com:8443

SSH
---
ssh -i ssh_key.pem ubuntu@44.220.87.247

BOOTSTRAP MONITORING
--------------------
1. SSH into the system (command above)
2. Tail the cloudinit logfile (Wait for it to output 'End of bootstrap script')
tail -f /var/log/cloud-init-output.log
3. Check the PyTorch API service (Wait for it to be listening on port 9000)
sudo systemctl status foundation
sudo netstat -tulpn | grep 9000

Remote Inference APIs (see api_usage.txt for how to use them)
------------------------------------------------------------
PyTorch FastAPI:
http://44.220.87.247:9443/generate

Open WebUI:
http://44.220.87.247:8443/api/chat/completions
```


# License
This project is licensed under the MIT License, which allows for reuse and modification with attribution. See the LICENSE file for details. All included third-party tools and libraries maintain their respective licenses. Enjoy your AI playground responsibly!

