SMHP_USER_ROLE_NAME=eks-smhp-user-a1
SMHP_USER_ROLE_ARN=$(aws iam get-role --role-name $SMHP_USER_ROLE_NAME --query 'Role.Arn' --output text)


## What is allowed for this user
cat > eks-smhp-user-policy.json << EOL
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sagemaker:DescribeCluster",
                "sagemaker:DescribeClusterNode",
                "sagemaker:ListClusterNodes",
                "sagemaker:ListClusters",
                "eks:DescribeCluster",
                "eks:DescribeAccessEntry"
            ],
            "Resource": "*"
        }
    ]
}
EOL

aws iam put-role-policy \
    --role-name $SMHP_USER_ROLE_NAME \
    --policy-name eks-smhp-user-policy \
    --policy-document file://eks-smhp-user-policy.json


aws eks create-access-entry \
 --cluster-name $EKS_CLUSTER_NAME \
 --principal-arn $SMHP_USER_ROLE_ARN \
 --type STANDARD \
 --region $AWS_REGION


aws eks associate-access-policy \
 --cluster-name $EKS_CLUSTER_NAME \
 --principal-arn $SMHP_USER_ROLE_ARN \
 --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
 --access-scope type=cluster \
 --region $AWS_REGION


aws eks associate-access-policy \
 --cluster-name $EKS_CLUSTER_NAME \
 --principal-arn $SMHP_USER_ROLE_ARN \
 --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
 --access-scope type=cluster \
 --region $AWS_REGION

# arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
# arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy

#  --access-scope '{"type": "cluster"}'
#  --access-scope '{"type": "namespace", "namespaces": ["default"]}'

# aws eks delete-access-entry \
#     --cluster-name $EKS_CLUSTER_NAME \
#     --principal-arn $EXECUTION_ROLE_ARN \
#     --region $AWS_REGION
