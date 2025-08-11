#!/bin/bash

echo "🔧 Configuração Service Account (Alternativa Organizacional)"
echo "=========================================================="

PROJECT_ID="stable-chain-455617-v1"
SERVICE_ACCOUNT_NAME="pdf-ocr-vision-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "📋 Verificando restrições organizacionais..."
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

# Configurar permissões corretas para Vision API
echo "🔑 Configurando permissões para Vision API..."

# Usar as roles corretas que existem
ROLES=(
    "roles/cloudvision.serviceAgent"
    "roles/ml.serviceAgent"
    "roles/serviceusage.serviceUsageConsumer"
)

for role in "${ROLES[@]}"; do
    echo "   Adicionando role: $role"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role" \
        --quiet >/dev/null 2>&1
done

echo "✅ Permissões configuradas"

# Como não podemos criar chaves, vamos usar impersonação
echo ""
echo "⚠️ ATENÇÃO: Organização impede criação de chaves de Service Account"
echo "💡 Usando abordagem alternativa: Impersonação de Service Account"
echo ""

# Configurar impersonação para a conta atual
CURRENT_ACCOUNT=$(gcloud config get-value account)
echo "🔧 Configurando impersonação para conta: $CURRENT_ACCOUNT"

# Dar permissão de impersonação
gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT_EMAIL \
    --member="user:$CURRENT_ACCOUNT" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --quiet

# Configurar gcloud para usar impersonação
gcloud config set auth/impersonate_service_account $SERVICE_ACCOUNT_EMAIL

echo "✅ Impersonação configurada"

# Criar script de configuração
echo "📄 Criando script de configuração..."
cat > /app/gcloud-config/setup_impersonation.sh << 'EOF'
#!/bin/bash
# Configuração de impersonação para Service Account

PROJECT_ID="stable-chain-455617-v1"
SERVICE_ACCOUNT_EMAIL="pdf-ocr-vision-sa@stable-chain-455617-v1.iam.gserviceaccount.com"

# Configurar impersonação
gcloud config set auth/impersonate_service_account $SERVICE_ACCOUNT_EMAIL
gcloud config set project $PROJECT_ID

# Configurar variáveis de ambiente para usar impersonação
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
export GCLOUD_IMPERSONATE_SERVICE_ACCOUNT="$SERVICE_ACCOUNT_EMAIL"

echo "✅ Impersonação ativada para: $SERVICE_ACCOUNT_EMAIL"
echo "   Projeto: $PROJECT_ID"
EOF

chmod +x /app/gcloud-config/setup_impersonation.sh

# Configurar variáveis de ambiente
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
export GCLOUD_IMPERSONATE_SERVICE_ACCOUNT="$SERVICE_ACCOUNT_EMAIL"

# Testar configuração
echo ""
echo "🧪 Testando configuração com impersonação..."

# Teste específico para impersonação
python3 -c "
import os
from google.cloud import vision
from google.auth import impersonated_credentials
from google.auth import default
import google.auth

try:
    # Tentar usar impersonação se configurada
    if os.getenv('GCLOUD_IMPERSONATE_SERVICE_ACCOUNT'):
        print('🔧 Usando impersonação de Service Account...')
        source_credentials, project = default()
        target_principal = os.getenv('GCLOUD_IMPERSONATE_SERVICE_ACCOUNT')
        
        credentials = impersonated_credentials.Credentials(
            source_credentials=source_credentials,
            target_principal=target_principal,
            target_scopes=['https://www.googleapis.com/auth/cloud-platform']
        )
        
        client = vision.ImageAnnotatorClient(credentials=credentials)
    else:
        print('🔧 Usando credenciais padrão...')
        client = vision.ImageAnnotatorClient()
    
    print('✅ Cliente criado com sucesso!')
    
    # Teste mínimo
    image = vision.Image()
    response = client.text_detection(image=image)
    
    if response.error.message:
        print(f'❌ Erro da API: {response.error.message}')
        exit(1)
    else:
        print('✅ API funcionando! Teste concluído com sucesso.')
        exit(0)
        
except Exception as e:
    print(f'❌ Erro: {e}')
    print(f'   Tipo: {type(e)}')
    exit(1)
"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCESSO! Service Account com impersonação funcionando!"
    echo ""
    echo "📋 Para usar em outros containers/sessões:"
    echo "   source /app/gcloud-config/setup_impersonation.sh"
    echo ""
    echo "💡 Vantagens desta abordagem:"
    echo "   ✅ Funciona com restrições organizacionais"
    echo "   ✅ Sem chaves locais (mais seguro)"
    echo "   ✅ Usa conta existente com impersonação"
    echo "   ✅ Audit trail completo"
else
    echo ""
    echo "❌ Erro no teste. Verificando configuração..."
    echo ""
    echo "🔍 Diagnóstico:"
    echo "   Projeto: $(gcloud config get-value project)"
    echo "   Conta: $(gcloud config get-value account)"
    echo "   Impersonação: $(gcloud config get-value auth/impersonate_service_account)"
fi 