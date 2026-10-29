#!/bin/bash

REGION="us-east-1"

echo "================================================================"
echo "🔍 PAINEL DE STATUS E ENDPOINTS DA INFRAESTRUTURA AWS"
echo "================================================================"

echo ""
echo "1. STATUS E ENDPOINTS DO RDS (PostgreSQL):"
aws rds describe-db-instances \
  --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address,Endpoint.Port]" \
  --output table \
  --region ${REGION}

echo ""
echo "2. STATUS E ENDPOINT DO ELASTICACHE (Redis):"
aws elasticache describe-cache-clusters \
  --cache-cluster-id evaluation-cache \
  --show-cache-node-info \
  --query "CacheClusters[*].[CacheClusterId,CacheClusterStatus,CacheNodes[0].Endpoint.Address,CacheNodes[0].Endpoint.Port]" \
  --output table \
  --region ${REGION} 2>/dev/null || echo "Ainda inicializando Redis..."

echo ""
echo "3. ENDPOINT DA FILA AWS SQS:"
aws sqs get-queue-url --queue-name togglemaster-events --query "QueueUrl" --output text --region ${REGION} 2>/dev/null || echo "Fila não encontrada."

echo ""
echo "4. TABELA DYNAMODB:"
aws dynamodb describe-table --table-name ToggleMasterAnalytics --query "Table.[TableName,TableStatus]" --output table --region ${REGION} 2>/dev/null || echo "Tabela não encontrada."

echo ""
echo "5. STATUS DO CLUSTER EKS (Kubernetes):"
aws eks describe-cluster --name togglemaster-cluster --query "cluster.[name,status,version]" --output table --region ${REGION} 2>/dev/null || echo "Cluster ainda inicializando..."

echo "================================================================"