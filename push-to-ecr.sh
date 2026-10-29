#!/bin/bash

# Encerra o script imediatamente se algum comando falhar
set -e

# 1. DEFINIÇÃO DE VARIÁVEIS
# Busca automaticamente o ID da sua conta AWS conectada no momento (não precisa deixar fixo!)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "===================================================="
echo "Iniciando processo para a Conta AWS: ${ACCOUNT_ID}"
echo "Região: ${REGION}"
echo "URL do ECR: ${ECR_URL}"
echo "===================================================="

# 2. AUTENTICAÇÃO DO DOCKER NA AWS
echo "1/3 -> Autenticando o Docker no Amazon ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL}

# 3. LISTA COM O NOME DOS 5 MICROSSERVIÇOS
SERVICES=("auth-service" "flag-service" "targeting-service" "evaluation-service" "analytics-service")

# 4. LOOP DE CRIAÇÃO, TAG E PUSH
for SERVICE in "${SERVICES[@]}"; do
  echo ""
  echo "----------------------------------------------------"
  echo "🚀 Processando: ${SERVICE}"
  echo "----------------------------------------------------"
  
  # Cria o repositório no ECR caso ele ainda não exista
  # O '|| true' no final garante que se o repositório já existir, o script não trava com erro
  aws ecr create-repository --repository-name ${SERVICE} --region ${REGION} 2>/dev/null || echo "Repositório ${SERVICE} já existe, continuando..."

  # Aplica o endereço da AWS como 'apelido' (tag) na imagem que compilamos na Etapa 1
  echo "Etiquetando (tagging) imagem local..."
  docker tag fase02-${SERVICE}:latest ${ECR_URL}/${SERVICE}:latest

  # Envia as camadas da imagem para os servidores da AWS
  echo "Enviando (pushing) imagem para o ECR..."
  docker push ${ECR_URL}/${SERVICE}:latest
done

echo ""
echo "===================================================="
echo "✅ SUCESSO: Todas as 5 imagens estão no Amazon ECR!"
echo "===================================================="