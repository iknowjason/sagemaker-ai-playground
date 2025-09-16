output "sagemaker_endpoint_name" {
  description = "The name of the deployed SageMaker inference endpoint"
  value       = aws_sagemaker_endpoint.foundation_sec_8b_ep.name
}

output "sagemaker_endpoint_url" {
  description = "The full SageMaker runtime URL for InvokeEndpoint"
  value       = "https://runtime.sagemaker.${var.aws_region}.amazonaws.com/endpoints/${aws_sagemaker_endpoint.foundation_sec_8b_ep.name}/invocations"
}
