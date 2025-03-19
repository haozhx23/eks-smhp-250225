
echo "HyperPod Cluster Execution Role to be created: $SMHP_CLUSTER_ROLE"

aws s3 mb s3://${LIFECYCLE_S3_BUCKET} --region ${AWS_REGION}

cat > smhp-compute-cluster-add-policy.json << EOL
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:AssignPrivateIpAddresses",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:DeleteNetworkInterfacePermission",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeVpcs",
                "ec2:DescribeDhcpOptions",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DetachNetworkInterface",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:UnassignPrivateIpAddresses",
                "ecr:BatchGetImage",
                "ecr:GetAuthorizationToken",
                "ecr:GetDownloadUrlForLayer",
                "eks-auth:AssumeRoleForPodIdentity"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:network-interface/*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${LIFECYCLE_S3_BUCKET}",
                "arn:aws:s3:::${LIFECYCLE_S3_BUCKET}/*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOL

cat > smhp-compute-cluster-trust.json << EOL
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "sagemaker.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOL



# 1: Create the IAM role with the trust relationship, for SageMaker Hyperpod
aws iam create-role \
    --role-name $SMHP_CLUSTER_ROLE \
    --assume-role-policy-document file://smhp-compute-cluster-trust.json

# 2: Attach the AWS-managed policy, required by SageMaker Hyperpod
aws iam attach-role-policy \
    --role-name $SMHP_CLUSTER_ROLE \
    --policy-arn arn:aws:iam::aws:policy/AmazonSageMakerClusterInstanceRolePolicy

# 3: Add the inline policy defined above
aws iam put-role-policy \
    --role-name $SMHP_CLUSTER_ROLE \
    --policy-name smhp-compute-cluster-add-policy \
    --policy-document file://smhp-compute-cluster-add-policy.json


# 4: Add pass role permission to Cluster Management Role for HyperPod Execution Role
## connect passrole policy of cluster role to admin role
cat > passrole-for-smhp-creation.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "$SMHP_CLUSTER_ROLE_ARN"
        }
    ]
}
EOF

aws iam put-role-policy \
  --role-name $ADMIN_ROLE_NAME \
  --policy-name passrole-for-smhp-creation \
  --policy-document file://passrole-for-smhp-creation.json
