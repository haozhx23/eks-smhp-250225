	

aws_region=us-east-1
# cluster_management_role_arn=arn:aws:iam::633205212955:role/eks-smhp-managment-role
cluster_management_role_name=eks-smhp-managment-role


eks_controlplane_cluster_name_to_create=eks-for-smhp-0321
eks_controlplane_role_name_to_create=eks-creation-role-0321

eks_subnets="subnet-0eb6ba27f14cd06ab,subnet-0296b3e96ff035fd5"
eks_sg=sg-0794066d51b2a83b6
eks_cidr=10.21.0.1/16



##############################################################################
### 1. Create role for EKS cluster Creation
##############################################################################

cat <<EOF > eks-cluster-role-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role with EKS only trust relationship
created_eks_role_arn=$(aws iam create-role \
  --role-name $eks_controlplane_role_name_to_create \
  --assume-role-policy-document file://eks-cluster-role-trust-policy.json \
  --output json | jq -r '.Role.Arn')

# created_eks_role_arn=$(aws iam get-role --role-name $eks_controlplane_role_name_to_create --query 'Role.Arn' --output text)

echo "Created EKS Exec role ARN: $created_eks_role_arn"


# Attach the AWS Managed policy required for EKS role
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
  --role-name $eks_controlplane_role_name_to_create

echo "Add AWS managed policy AmazonEKSClusterPolicy to : $created_eks_role_arn"

##############################################################################
### 2. Add passrole permission to the cluster management role
### so the cluster management role can be passed to the eks-cluster-role created above
##############################################################################

cat > passrole-for-eks-creation-policy.json << EOL
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "${created_eks_role_arn}"
        }
    ]
}
EOL

aws iam put-role-policy \
    --role-name $cluster_management_role_name \
    --policy-name passrole-for-eks-creation-policy \
    --policy-document file://passrole-for-eks-creation-policy.json

echo "Put resource-limited passRole permission on ClusterManagementRole ($cluster_management_role_name) for resource $created_eks_role_arn"

## make sure above changes taken effect
sleep 10

##############################################################################
### 3. Create EKS Cluster
##############################################################################

aws eks create-cluster \
  --region $aws_region \
  --name $eks_controlplane_cluster_name_to_create \
  --kubernetes-version 1.31 \
  --role-arn $created_eks_role_arn \
  --access-config authenticationMode=API_AND_CONFIG_MAP \
  --resources-vpc-config \
    subnetIds=$eks_subnets,securityGroupIds=$eks_sg,endpointPublicAccess=true,endpointPrivateAccess=true \
  --kubernetes-network-config \
    ipFamily=ipv4,serviceIpv4Cidr=$eks_cidr


##############################################################################
echo "Wati untill EKS control plane cluster is InService (about 15min)"
##############################################################################