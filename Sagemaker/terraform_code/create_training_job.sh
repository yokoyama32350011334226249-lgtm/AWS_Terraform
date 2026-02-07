#!/bin/bash

# ===== SageMaker Training Job 実行スクリプト =====
# 目的: AWS CLI を使用して DeepAR モデルの学習ジョブを実行
# 使用方法: Terraform の local-exec プロビジョナーから呼び出される

set -e

# 環境変数の確認
echo "=========================================="
echo "SageMaker Training Job 実行開始"
echo "=========================================="
echo "プロジェクト名: ${PROJECT_NAME}"
echo "リージョン: ${AWS_REGION}"
echo "トレーニングデータ: ${TRAINING_DATA_URI}"
echo "出力パス: ${OUTPUT_PATH}"
echo "ジョブ名: ${TRAINING_JOB_NAME}"
echo "=========================================="

# トレーニングジョブの設定 JSON を作成
cat > /tmp/training_job_config.json << EOF
{
  "TrainingJobName": "${TRAINING_JOB_NAME}",
  "RoleArn": "${IAM_ROLE_ARN}",
  "AlgorithmSpecification": {
    "TrainingImage": "246618743249.dkr.ecr.ap-northeast-1.amazonaws.com/sagemaker-forecasting-deepar:1",
    "TrainingInputMode": "File"
  },
  "InputDataConfig": [
    {
      "ChannelName": "training",
      "DataSource": {
        "S3DataSource": {
          "S3Uri": "${TRAINING_DATA_URI}",
          "S3DataType": "S3Prefix",
          "S3DataDistributionType": "FullyReplicated"
        }
      },
      "ContentType": "application/x-recordio-protobuf",
      "CompressionType": "None"
    }
  ],
  "OutputDataConfig": {
    "S3OutputPath": "${OUTPUT_PATH}"
  },
  "ResourceConfig": {
    "InstanceType": "ml.m5.large",
    "InstanceCount": 1,
    "VolumeSizeInGB": 30
  },
  "StoppingCondition": {
    "MaxRuntimeInSeconds": 86400
  },
  "HyperParameters": {
    "time_freq": "D",
    "prediction_length": "7",
    "context_length": "20",
    "epochs": "20",
    "mini_batch_size": "32",
    "learning_rate": "0.001",
    "dropout_rate": "0.1",
    "num_layers": "2",
    "num_cells": "40"
  },
  "Tags": [
    {
      "Key": "Project",
      "Value": "${PROJECT_NAME}"
    },
    {
      "Key": "Environment",
      "Value": "production"
    },
    {
      "Key": "ManagedBy",
      "Value": "Terraform"
    }
  ]
}
EOF

echo ""
echo "トレーニングジョブ設定ファイルを作成しました: /tmp/training_job_config.json"
echo ""

# AWS CLI を使用してトレーニングジョブを作成
echo "トレーニングジョブを作成中..."

aws sagemaker create-training-job \
  --region "${AWS_REGION}" \
  --profile "${AWS_PROFILE}" \
  --cli-input-json file:///tmp/training_job_config.json

echo ""
echo "=========================================="
echo "トレーニングジョブの作成が完了しました"
echo "ジョブ名: ${TRAINING_JOB_NAME}"
echo ""
echo "進行状況の確認:"
echo "  aws sagemaker describe-training-job --training-job-name ${TRAINING_JOB_NAME} --region ${AWS_REGION} --profile ${AWS_PROFILE}"
echo ""
echo "CloudWatch ログの確認:"
echo "  /aws/sagemaker/TrainingJobs/${TRAINING_JOB_NAME}"
echo "=========================================="

# 設定ファイルの削除
rm -f /tmp/training_job_config.json

echo "トレーニングジョブの実行スクリプトが完了しました"
