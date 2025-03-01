

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



# 1: Create the IAM role with the trust policy
aws iam create-role \
    --role-name $SMHP_CLUSTER_ROLE \
    --assume-role-policy-document file://smhp-compute-cluster-trust.json

# Step 2: Attach the AWS-managed policy
aws iam attach-role-policy \
    --role-name $SMHP_CLUSTER_ROLE \
    --policy-arn arn:aws:iam::aws:policy/AmazonSageMakerClusterInstanceRolePolicy

# Step 3: Add the inline policy
aws iam put-role-policy \
    --role-name $SMHP_CLUSTER_ROLE \
    --policy-name smhp-compute-cluster-add-policy \
    --policy-document file://smhp-compute-cluster-add-policy.json



cat > hyperpod-eks-policy.json << EOL
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "${SMHP_CLUSTER_ROLE_ARN}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:CreateAccessEntry",
                "eks:DescribeAccessEntry",
                "eks:DeleteAccessEntry",
                "eks:AssociateAccessPolicy",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DescribeSecurityGroups",
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*"
        }
    ]
}
EOL

aws iam create-policy \
    --policy-name hyperpod-eks-policy \
    --policy-document file://hyperpod-eks-policy.json



POLICIES=(
    # "arn:aws:iam::${ACCOUNT_ID}:policy/hyperpod-eks-policy"
    # "arn:aws:iam::${ACCOUNT_ID}:policy/cfn-stack-policy"
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    # "arn:aws:iam::aws:policy/AmazonSageMakerClusterInstanceRolePolicy"
    # "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
)

for policy in "${POLICIES[@]}"; do
    echo "Adding policy $policy"
    aws iam attach-role-policy \
        --role-name "$SMHP_CLUSTER_ROLE" \
        --policy-arn "$policy"
done

## connect passrole policy of cluster role to admin role

cat > passrole-policy-for-admin.json << EOF
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

# Add the inline policy to your role
aws iam put-role-policy \
  --role-name $ADMIN_ROLE_NAME \
  --policy-name passrole-policy-for-admin \
  --policy-document file://passrole-policy-for-admin.json

