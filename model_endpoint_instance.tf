terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "hf_token" {
  description = "Hugging Face API token with access to the Cisco Foundation Model"
  type        = string
  sensitive   = true
  default     = ""
}

variable "hf_model_id" {
  description = "Hugging Face Model ID"
  default = "fdtn-ai/Foundation-Sec-8B-Instruct"
}

variable "hf_container_image" {
  description = "The Hugging Face TGI container image"
  default     = "763104351884.dkr.ecr.us-east-1.amazonaws.com/huggingface-pytorch-tgi-inference:2.7.0-tgi3.3.4-gpu-py311-cu124-ubuntu22.04"
}

resource "aws_iam_role" "sagemaker_execution_role" {
  name = "sagemaker_execution_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "sagemaker.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "time_sleep" "wait_for_role_propagation" {
  depends_on = [
    aws_iam_role.sagemaker_execution_role,
    aws_iam_role_policy_attachment.sagemaker_full_access
  ]
  create_duration = "30s"
}

resource "aws_sagemaker_model" "foundation_sec_8b" {
  name               = "foundation-sec-8b-instruct-model"
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  primary_container {
    image = var.hf_container_image 
    environment = {
      HF_MODEL_ID = var.hf_model_id 
      SM_NUM_GPUS = "1"                                
      HUGGING_FACE_HUB_TOKEN = var.hf_token 
    }
  }

  depends_on = [time_sleep.wait_for_role_propagation]
}

resource "aws_sagemaker_endpoint_configuration" "foundation_sec_8b_cfg" {
  name = "foundation-sec-8b-endpoint-cfg"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.foundation_sec_8b.name
    initial_instance_count = 1
    instance_type          = "ml.g5.2xlarge"
  }

  depends_on = [aws_sagemaker_model.foundation_sec_8b]
}

resource "aws_sagemaker_endpoint" "foundation_sec_8b_ep" {
  name                 = "foundation-sec-8b-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.foundation_sec_8b_cfg.name

  depends_on = [aws_sagemaker_endpoint_configuration.foundation_sec_8b_cfg]
}



