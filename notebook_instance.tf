resource "random_string" "notebook_suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_iam_role_policy" "notebook_additional_permissions" {
  name = "notebook-additional-permissions"
  role = aws_iam_role.sagemaker_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateNotebookInstanceLifecycleConfig",
          "sagemaker:DescribeNotebookInstanceLifecycleConfig",
          "sagemaker:UpdateNotebookInstanceLifecycleConfig",
          "sagemaker:DeleteNotebookInstanceLifecycleConfig",
          "sagemaker:InvokeEndpoint",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "notebook_setup" {
  name = "cisco-notebook-setup-${random_string.notebook_suffix.result}"

  on_create = base64encode(<<-EOF
    #!/bin/bash
    set -e
    exec > >(tee /var/log/sagemaker-lifecycle-start.log) 2>&1

    echo "Running on_start lifecycle at $(date)"
    
    # Install packages
    echo "Installing packages"
    /home/ec2-user/anaconda3/bin/pip install transformers torch pandas numpy boto3 --quiet

    # Clone the repository manually
    echo "Cloning repository for jupyter notebook samples"
    cd /home/ec2-user/SageMaker
    git clone https://github.com/iknowjason/cisco-foundation-notebooks.git

    if [ $? -eq 0 ]; then
        echo "Repository cloned successfully"
        cd cisco-foundation-notebooks
   
        # Update variable names 
        find . -name "*.ipynb" -exec sed -i "s/endpoint_name = 'foundation-sec-8b-endpoint'/endpoint_name = '${aws_sagemaker_endpoint.foundation_sec_8b_ep.name}'/g" {} \;
        find . -name "*.ipynb" -exec sed -i "s/aws_region = 'us-east-1'/aws_region = '${var.aws_region}'/g" {} \;
    
        echo "Notebooks updated successfully"
    else
        echo "Failed to clone repository"
        exit 1
    fi

EOF
)
}

# SageMaker Managed Notebook Instance
resource "aws_sagemaker_notebook_instance" "cisco_cookbook" {
  name                   = "cisco-foundation-cookbook-${random_string.notebook_suffix.result}"
  role_arn               = aws_iam_role.sagemaker_execution_role.arn
  instance_type          = "ml.t3.medium"

  lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.notebook_setup.name

  depends_on = [
    aws_sagemaker_endpoint.foundation_sec_8b_ep,
    aws_iam_role_policy_attachment.sagemaker_notebook_access,
    aws_iam_role_policy.notebook_additional_permissions
  ]

  tags = {
    Name = "Cisco Foundation AI Cookbook"
  }
}

resource "aws_iam_role_policy_attachment" "sagemaker_notebook_access" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerReadOnly"
}

output "notebook_instance_url" {
  value = "https://${aws_sagemaker_notebook_instance.cisco_cookbook.name}.notebook.${var.aws_region}.sagemaker.aws/tree"
}

output "notebook_instance_name" {
  value = aws_sagemaker_notebook_instance.cisco_cookbook.name
}
