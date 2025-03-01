aws iam attach-role-policy \
--role-name $SMHP_CLUSTER_ROLE \
--policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

aws eks create-addon --addon-name amazon-cloudwatch-observability --cluster-name $EKS_CLUSTER_NAME