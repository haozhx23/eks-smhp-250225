
curl https://raw.githubusercontent.com/aws-samples/awsome-distributed-training/main/1.architectures/7.sagemaker-hyperpod-eks/LifecycleScripts/base-config/on_create.sh --output on_create.sh

aws s3 cp on_create.sh $LIFECYCLE_S3_PATH
rm -r on_create.sh

cat > $CLUSTER_CONF_NAME << EOL
{
    "ClusterName": "${HP_CLUSTER_NAME}",
    "Orchestrator": { 
      "Eks": 
      {
        "ClusterArn": "${EKS_CLUSTER_ARN}"
      }
    },
    "InstanceGroups": [
      {
        "InstanceGroupName": "worker-group-1",
        "InstanceType": "${ACCEL_INSTANCE_TYPE}",
        "InstanceCount": ${ACCEL_COUNT},
        "InstanceStorageConfigs": [
          {
            "EbsVolumeConfig": {
              "VolumeSizeInGB": ${ACCEL_VOLUME_SIZE}
            }
          }
        ],
        "LifeCycleConfig": {
          "SourceS3Uri": "${LIFECYCLE_S3_PATH}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${SMHP_CLUSTER_ROLE_ARN}",
        "ThreadsPerCore": ${THREAD_PER_CORE},
        "OnStartDeepHealthChecks": ["InstanceStress", "InstanceConnectivity"]
      }
    ],
    "VpcConfig": {
      "SecurityGroupIds": ["$SECURITY_GROUP"],
      "Subnets":["$SUBNET_ID"]
    },
    "NodeRecovery": "${NODE_RECOVERY}"
}
EOL