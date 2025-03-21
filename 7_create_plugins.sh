aws iam attach-role-policy \
--role-name $SMHP_CLUSTER_EXEC_ROLE \
--policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

aws eks create-addon --addon-name amazon-cloudwatch-observability --cluster-name $EKS_CLUSTER_NAME

aws eks create-addon --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --addon-name amazon-sagemaker-hyperpod-taskgovernance

aws eks describe-addon --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --addon-name amazon-sagemaker-hyperpod-taskgovernance
