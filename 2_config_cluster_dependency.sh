
## If the EKS control plane is created using the ClusterManagementRole, the access-entry and associate will not be necessary
# aws eks create-access-entry \
#  --cluster-name $EKS_CLUSTER_NAME \
#  --principal-arn $ADMIN_ROLE_ARM \
#  --type STANDARD \
#  --region $AWS_REGION

# aws eks associate-access-policy \
#  --cluster-name $EKS_CLUSTER_NAME \
#  --principal-arn $ADMIN_ROLE_ARM \
#  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
#  --access-scope type=cluster \
#  --region $AWS_REGION

# aws eks delete-access-entry \
#     --cluster-name $EKS_CLUSTER_NAME \
#     --principal-arn $EXECUTION_ROLE_ARN \
#     --region $AWS_REGION


aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
## Verify Cluster connection
kubectl config current-context
kubectl get svc

cd ..
git clone https://github.com/aws/sagemaker-hyperpod-cli.git
cd sagemaker-hyperpod-cli/helm_chart

helm lint HyperPodHelmChart
helm dependencies update HyperPodHelmChart
# helm install dependencies HyperPodHelmChart --dry-run
helm install dependencies HyperPodHelmChart --namespace kube-system
# helm list --namespace kube-system
cd ../..

echo '---- Start Validation ----'
echo `helm list --namespace kube-system`
echo `kubectl get ds health-monitoring-agent -n aws-hyperpod`
echo `kubectl get ds dependencies-aws-efa-k8s-device-plugin -n kube-system`
echo `kubectl get deploy dependencies-training-operators -n kubeflow`
echo `kubectl get crd | grep kubeflow`
echo `kubectl get deploy dependencies-mpi-operator -n kube-system`
echo `kubectl get crd mpijobs.kubeflow.org -n kubeflow -o jsonpath='{.status.storedVersions[]}'`
echo `kubectl get priorityclass`
echo '---- End Validation ----'

