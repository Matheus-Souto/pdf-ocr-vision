#!/bin/bash

echo "🤖 Configuração de Service Account Automatizada"
echo "=============================================="

PROJECT_ID="stable-chain-455617-v1"
SERVICE_ACCOUNT_NAME="pdf-ocr-vision-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="/app/gcloud-config/service-account-key.json"

echo "📋 Configurando Service Account para autenticação automática..."
echo "   Projeto: $PROJECT_ID"
echo "   Service Account: $SERVICE_ACCOUNT_EMAIL"
echo ""

# Verificar se gcloud está instalado e autenticado
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI não encontrado!"
    exit 1
fi

# Verificar se está autenticado
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
    echo "❌ Você precisa estar autenticado primeiro!"
    echo "💡 Execute: gcloud auth login --no-launch-browser"
    exit 1
fi

# Configurar projeto
echo "🎯 Configurando projeto..."
gcloud config set project $PROJECT_ID

# Verificar se a Service Account já existe
echo "🔍 Verificando se Service Account já existe..."
if gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL >/dev/null 2>&1; then
    echo "✅ Service Account já existe: $SERVICE_ACCOUNT_EMAIL"
else
    echo "🔧 Criando Service Account..."
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --description="Service Account para PDF OCR Vision API" \
        --display-name="PDF OCR Vision Service Account"
    
    if [ $? -eq 0 ]; then
        echo "✅ Service Account criada: $SERVICE_ACCOUNT_EMAIL"
    else
        echo "❌ Erro ao criar Service Account"
        exit 1
    fi
fi

# Verificar se já tem as permissões necessárias
echo "🔑 Configurando permissões..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/cloudvision.admin" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/storage.objectViewer" \
    --quiet

echo "✅ Permissões configuradas"

# Gerar chave da Service Account
echo "🔐 Gerando chave da Service Account..."
if [ -f "$KEY_FILE" ]; then
    echo "⚠️ Arquivo de chave já existe. Removendo..."
    rm "$KEY_FILE"
fi

gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SERVICE_ACCOUNT_EMAIL"

if [ -f "$KEY_FILE" ]; then
    echo "✅ Chave criada: $KEY_FILE"
    chmod 600 "$KEY_FILE"
else
    echo "❌ Erro ao criar chave"
    exit 1
fi

# Configurar variáveis de ambiente
echo "🌍 Configurando variáveis de ambiente..."
export GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE"
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"

# Criar arquivo de configuração permanente
echo "📄 Criando arquivo de configuração permanente..."
cat > /app/gcloud-config/env_vars.sh << EOF
#!/bin/bash
# Configuração automática para Google Cloud
export GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE"
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"

echo "✅ Variáveis de ambiente configuradas:"
echo "   GOOGLE_APPLICATION_CREDENTIALS=\$GOOGLE_APPLICATION_CREDENTIALS"
echo "   GOOGLE_CLOUD_PROJECT=\$GOOGLE_CLOUD_PROJECT"
EOF

chmod +x /app/gcloud-config/env_vars.sh

# Testar configuração
echo ""
echo "🧪 Testando configuração da Service Account..."
python test_api_working.py

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCESSO! Service Account configurada e funcionando!"
    echo ""
    echo "📋 Para usar em outros containers/sessões:"
    echo "   1. Execute: source /app/gcloud-config/env_vars.sh"
    echo "   2. Ou adicione ao seu .bashrc:"
    echo "      echo 'source /app/gcloud-config/env_vars.sh' >> ~/.bashrc"
    echo ""
    echo "💡 Vantagens da Service Account:"
    echo "   ✅ Sem reautenticação manual"
    echo "   ✅ Funciona em ambientes automatizados"
    echo "   ✅ Não expira como credenciais de usuário"
    echo "   ✅ Ideal para produção"
else
    echo ""
    echo "❌ Erro no teste. Verifique as configurações."
fi 