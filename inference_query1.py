import boto3, json, requests
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.session import get_session

region = "us-east-1"
endpoint_name = "foundation-sec-8b-endpoint"

payload = {
    "inputs": "List top cloud security risks",
    "parameters": {"max_new_tokens": 200}
}

client = boto3.client("sagemaker-runtime", region_name=region)
response = client.invoke_endpoint(
    EndpointName=endpoint_name,
    ContentType="application/json",
    Body=json.dumps(payload),
)

print(response["Body"].read().decode("utf-8"))
