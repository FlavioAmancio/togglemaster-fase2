#!/bin/bash

# Encerra caso ocorra erro grave inesperado
set -e

# ==============================================================================
# CONFIGURAÇÕES GERAIS
# ==============================================================================
REGION="us-east-1"
DB_PASS="ToggleMaster2024!"  # Senha forte padrão para os 3 bancos RDS

echo "================================================================"
echo "🚀 INICIANDO PROVISIONAMENTO DE DADOS: REDIS & RDS POSTGRESQL"
echo "================================================================"

# ==============================================================================
# 1. MAPEAMENTO DE REDE (VPC E SUBNETS)
# ==============================================================================
# Descobre dinamicamente a VPC Padrão da sua conta AWS Academy e seu Security Group
echo "1/4 -> Coletando informações de rede da VPC Padrão..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region ${REGION})
SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${VPC_ID}" "Name=group-name,Values=default" --query "SecurityGroups[0].GroupId" --output text --region ${REGION})
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[*].SubnetId" --output text --region ${REGION})

echo "      VPC identificada: ${VPC_ID}"
echo "      Security Group identificado: ${SG_ID}"

# ==============================================================================
# 2. LIBERAÇÃO DE PORTAS DE COMUNICAÇÃO
# ==============================================================================
# Abre as portas necessárias para que o Kubernetes e você consigam falar com os bancos
echo "2/4 -> Liberando portas de acesso no Firewall (Security Group)..."
# Porta 5432: Padrão mundial do PostgreSQL
aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port 5432 --cidr 0.0.0.0/0 --region ${REGION} 2>/dev/null || echo "      Porta 5432 já estava liberada."
# Porta 6379: Padrão mundial do Redis
aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port 6379 --cidr 0.0.0.0/0 --region ${REGION} 2>/dev/null || echo "      Porta 6379 já estava liberada."

# ==============================================================================
# 3. PROVISIONAMENTO DO REDIS (ELASTICACHE)
# ==============================================================================
# O ElastiCache exige um 'Subnet Group' (grupo de sub-redes) antes de criar o cluster
echo "3/4 -> Solicitando criação do Cluster Redis (ElastiCache)..."
aws elasticache create-cache-subnet-group \
  --cache-subnet-group-name "togglemaster-cache-subnet" \
  --cache-subnet-group-description "Subnet group para o cluster Redis ToggleMaster" \
  --subnet-ids ${SUBNET_IDS} \
  --region ${REGION} 2>/dev/null || echo "      Subnet Group já existe."

# Cria o nó de cache Redis (tamanho t3.micro, o mais econômico)
aws elasticache create-cache-cluster \
  --cache-cluster-id "evaluation-cache" \
  --engine redis \
  --cache-node-type cache.t3.micro \
  --num-cache-nodes 1 \
  --cache-subnet-group-name "togglemaster-cache-subnet" \
  --security-group-ids ${SG_ID} \
  --region ${REGION} 2>/dev/null || echo "      Cluster Redis já solicitado anteriormente."

# ==============================================================================
# 4. PROVISIONAMENTO DAS 3 INSTÂNCIAS POSTGRESQL (RDS)
# ==============================================================================
echo "4/4 -> Solicitando criação das 3 instâncias de banco RDS PostgreSQL..."

# 4.1 Banco do auth-service
echo "      -> Criando banco: auth-db..."
aws rds create-db-instance \
  --db-instance-identifier auth-db \
  --db-name auth_db \
  --engine postgres \
  --engine-version 15 \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 \
  --master-username postgres \
  --master-user-password "${DB_PASS}" \
  --publicly-accessible \
  --vpc-security-group-ids ${SG_ID} \
  --backup-retention-period 0 \
  --no-multi-az \
  --region ${REGION} 2>/dev/null || echo "      auth-db já solicitado anteriormente."

# 4.2 Banco do flag-service
echo "      -> Criando banco: flag-db..."
aws rds create-db-instance \
  --db-instance-identifier flag-db \
  --db-name flags_db \
  --engine postgres \
  --engine-version 15 \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 \
  --master-username postgres \
  --master-user-password "${DB_PASS}" \
  --publicly-accessible \
  --vpc-security-group-ids ${SG_ID} \
  --backup-retention-period 0 \
  --no-multi-az \
  --region ${REGION} 2>/dev/null || echo "      flag-db já solicitado anteriormente."

# 4.3 Banco do targeting-service
echo "      -> Criando banco: targeting-db..."
aws rds create-db-instance \
  --db-instance-identifier targeting-db \
  --db-name targeting_db \
  --engine postgres \
  --engine-version 15 \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 \
  --master-username postgres \
  --master-user-password "${DB_PASS}" \
  --publicly-accessible \
  --vpc-security-group-ids ${SG_ID} \
  --backup-retention-period 0 \
  --no-multi-az \
  --region ${REGION} 2>/dev/null || echo "      targeting-db já solicitado anteriormente."

echo ""
echo "================================================================"
echo "✅ PEDIDOS ENVIADOS! A AWS está construindo a infraestrutura."
echo "   (Status: criando em segundo plano na nuvem)"
echo "================================================================"