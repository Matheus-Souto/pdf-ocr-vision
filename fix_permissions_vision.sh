#!/bin/bash

echo "🔧 Correção de Permissões para Google Cloud Vision API"
echo "===================================================="

PROJECT_ID="stable-chain-455617-v1"
SERVICE_ACCOUNT_EMAIL="pdf-ocr-vision-sa@${PROJECT_ID}.iam.gserviceaccount.com"

echo "📋 Corrigindo permissões para Vision API..."
echo "   Projeto: $PROJECT_ID"
echo "   Service Account: $SERVICE_ACCOUNT_EMAIL"
echo ""

# Verificar se gcloud está instalado e autenticado
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI não encontrado!"
    exit 1
fi

# Configurar projeto
gcloud config set project $PROJECT_ID

# Verificar se a Service Account existe
if ! gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL >/dev/null 2>&1; then
    echo "❌ Service Account não encontrada: $SERVICE_ACCOUNT_EMAIL"
    echo "💡 Execute primeiro: ./setup_service_account_alt.sh"
    exit 1
fi

echo "✅ Service Account encontrada"

# Remover role incorreta se existir
echo "🧹 Removendo roles incorretas..."
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/cloudvision.admin" \
    --quiet >/dev/null 2>&1 || true

# Adicionar roles corretas para Vision API
echo "🔑 Adicionando permissões corretas para Vision API..."

# Roles necessárias para Vision API
CORRECT_ROLES=(
    "roles/cloudvision.serviceAgent"
    "roles/ml.serviceAgent" 
    "roles/serviceusage.serviceUsageConsumer"
    "roles/storage.objectViewer"
)

for role in "${CORRECT_ROLES[@]}"; do
    echo "   ✅ Adicionando: $role"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role" \
        --quiet
done

echo ""
echo "✅ Permissões corrigidas!"

# Verificar permissões atuais
echo ""
echo "🔍 Verificando permissões atuais da Service Account..."
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:serviceAccount:$SERVICE_ACCOUNT_EMAIL"

echo ""
echo "✅ Correção concluída!"
echo "💡 Agora execute: ./setup_service_account_alt.sh" 