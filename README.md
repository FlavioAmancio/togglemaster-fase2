# 🚀 ToggleMaster – Ecossistema de Microsserviços Distribuídos

Este repositório contém a evolução da plataforma **ToggleMaster** da Fase 1 (monolítica) para uma arquitetura distribuída de microsserviços conteinerizados e orquestrados na nuvem da AWS via **Kubernetes (Amazon EKS)**.

---

## 🏛️ Arquitetura dos Microsserviços

O ecossistema é composto por 5 microsserviços distribuídos:

1. **`auth-service` (Go 1.22):** Gerencia chaves de API e autenticação.  
   * *Banco:* PostgreSQL (`auth_db`)
2. **`flag-service` (Python / Flask):** CRUD das definições de feature flags.  
   * *Banco:* PostgreSQL (`flags_db`)
3. **`targeting-service` (Python / Flask):** Gerencia regras de segmentação (ex: 50% dos usuários).  
   * *Banco:* PostgreSQL (`targeting_db`)
4. **`evaluation-service` (Go 1.22):** O *hot path* de alta performance que avalia e retorna a decisão final (`true`/`false`).  
   * *Cache:* Redis | *Mensageria:* AWS SQS
5. **`analytics-service` (Python / Flask):** Worker que consome eventos do SQS e persiste métricas.  
   * *Fila:* AWS SQS | *Banco:* AWS DynamoDB

---

## 💻 1. Como Executar Localmente (Docker Compose)

O ambiente local sobe todos os **5 microsserviços e seus 4 bancos locais** (2 instâncias PostgreSQL, 1 Redis e 1 DynamoDB Local), totalizando **9 contêineres**.

### Pré-requisitos:
* [Docker](https://www.docker.com/) e Docker Compose instalados.

### Execução:
Na raiz do projeto, execute:

\`\`\`bash
# 1. Compila as imagens e sobe os 9 contêineres em segundo plano
docker compose up --build -d

# 2. Verifica se todos os 9 contêineres estão saudáveis
docker compose ps
\`\`\`

### Testando a integridade local:
\`\`\`bash
curl http://localhost:8001/health && \
curl http://localhost:8002/health && \
curl http://localhost:8003/health && \
curl http://localhost:8004/health && \
curl http://localhost:8005/health
\`\`\`
*Todos devem responder `{"status":"ok"}`.*

### Para parar o ambiente local:
\`\`\`bash
docker compose down
\`\`\`

---

## ☁️ 2. Como Provisionar e Executar na Nuvem (AWS EKS)

Toda a infraestrutura de nuvem foi projetada para a **AWS Academy** respeitando o uso obrigatório da `LabRole`.

### Ordem de Execução dos Scripts:

#### Passo 1: Enviar imagens para o Amazon ECR
\`\`\`bash
./push-to-ecr.sh
\`\`\`
*Cria os 5 repositórios privados no ECR e faz o push das imagens compiladas.*

#### Passo 2: Provisionar Bancos e Mensageria
\`\`\`bash
./provision-databases.sh
\`\`\`
*Cria a fila SQS, tabela DynamoDB, cluster Redis no ElastiCache e 3 instâncias RDS PostgreSQL.*

#### Passo 3: Criar o Cluster EKS e Node Group (Console AWS)
1. Crie o cluster **`togglemaster-cluster`** com a **`LabRole`** (Modo automático desabilitado).
2. Adicione o Managed Node Group **`togglemaster-nodegroup`** com a **`LabRole`** (Mínimo=1, Desejado=2, Máximo=4).
3. Conecte o terminal local ao cluster:
   \`\`\`bash
   aws eks update-kubeconfig --name togglemaster-cluster --region us-east-1
   \`\`\`

#### Passo 4: Inicializar Schemas no RDS
Assim que os bancos ficarem com status `available`:
\`\`\`bash
./init-cloud-dbs.sh
\`\`\`

#### Passo 5: Instalar Ingress Controller e Metrics Server
\`\`\`bash
# Ingress Nginx (Gera o Network Load Balancer público da AWS)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/aws/deploy.yaml

# Metrics Server (Para o HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
\`\`\`

#### Passo 6: Implantar os Manifestos da Aplicação
\`\`\`bash
kubectl apply -f k8s/
\`\`\`

#### Passo 7: Ajuste de Permissão IMDSv2 (Essencial no EKS)
Para permitir que os pods herdem a `LabRole` da máquina e acessem SQS e DynamoDB:
\`\`\`bash
INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=togglemaster-cluster" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].InstanceId" --output text --region us-east-1)
for ID in $INSTANCE_IDS; do
  aws ec2 modify-instance-metadata-options --instance-id $ID --http-put-response-hop-limit 2 --http-endpoint enabled --region us-east-1 > /dev/null
done
kubectl rollout restart deployment/evaluation-service deployment/analytics-service -n togglemaster
\`\`\`

---

## 📈 3. Teste de Carga e Autoscaling (HPA)

Para demonstrar a escalabilidade horizontal dos pods sob estresse:

\`\`\`bash
# Dispara 3.000 requisições simultâneas via ApacheBench
ab -n 3000 -c 50 "http://<SEU-LOAD-BALANCER>/evaluate?user_id=teste&flag_name=enable-new-dashboard"

# Acompanhe os pods escalando em tempo real:
kubectl get hpa -n togglemaster
kubectl get pods -n togglemaster
\`\`\`

---

## 📚 4. Relatório Técnico e Documentação Completa
O relatório detalhado contendo a análise arquitetural, justificativas teóricas, desafios operacionais e evidências fotográficas está disponível no arquivo **`docs/relatorio-tecnico.pdf`**.