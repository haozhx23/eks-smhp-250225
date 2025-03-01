
aws sagemaker create-cluster \
    --cli-input-json file://$CLUSTER_CONF_NAME \
    --region $AWS_REGION

aws sagemaker list-clusters \
 --output table \
 --region $AWS_REGION
