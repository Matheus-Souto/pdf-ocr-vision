#!/bin/bash

echo "🔧 Correção do Problema BMG - Credenciais"
echo "========================================"

# Restaurar credenciais corretas
echo "📥 Restaurando credenciais corretas..."
source /app/gcloud-config/activate_credentials.sh

# Remover arquivo de Service Account vazio que está causando problema
echo "🗑️ Removendo arquivo de Service Account vazio..."
SERVICE_ACCOUNT_FILE="/app/gcloud-config/service-account-key.json"
if [ -f "$SERVICE_ACCOUNT_FILE" ]; then
    FILE_SIZE=$(stat -c%s "$SERVICE_ACCOUNT_FILE" 2>/dev/null || echo "0")
    if [ "$FILE_SIZE" -eq 0 ]; then
        echo "   ❌ Arquivo vazio detectado: $SERVICE_ACCOUNT_FILE"
        rm "$SERVICE_ACCOUNT_FILE"
        echo "   ✅ Arquivo vazio removido"
    else
        echo "   ℹ️ Arquivo não está vazio ($FILE_SIZE bytes)"
    fi
else
    echo "   ℹ️ Arquivo não existe"
fi

# Configurar variáveis de ambiente corretas
echo "🌍 Configurando variáveis de ambiente..."
export GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json"
export GOOGLE_CLOUD_PROJECT="stable-chain-455617-v1"

# Remover qualquer referência ao arquivo de Service Account vazio
unset GCLOUD_IMPERSONATE_SERVICE_ACCOUNT

echo ""
echo "📋 Configuração atual:"
echo "   GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"
echo "   GOOGLE_CLOUD_PROJECT: $GOOGLE_CLOUD_PROJECT"

# Verificar se arquivo de credenciais existe e não está vazio
if [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    FILE_SIZE=$(stat -c%s "$GOOGLE_APPLICATION_CREDENTIALS")
    echo "   ✅ Arquivo de credenciais: $FILE_SIZE bytes"
else
    echo "   ❌ Arquivo de credenciais não encontrado!"
    exit 1
fi

# Testar criação do cliente Vision
echo ""
echo "🧪 Testando criação do cliente Vision..."
python3 -c "
import os
from google.cloud import vision

# Configurar ambiente
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/root/.config/gcloud/application_default_credentials.json'
os.environ['GOOGLE_CLOUD_PROJECT'] = 'stable-chain-455617-v1'

try:
    client = vision.ImageAnnotatorClient()
    print('✅ Cliente Vision criado com sucesso!')
    print('✅ Problema corrigido!')
except Exception as e:
    print(f'❌ Ainda há erro: {e}')
    exit(1)
"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 PROBLEMA BMG CORRIGIDO!"
    echo "========================="
    echo ""
    echo "✅ Arquivo de Service Account vazio removido"
    echo "✅ Application Default Credentials configuradas"
    echo "✅ Cliente Vision funcionando"
    echo ""
    echo "🚀 Sua aplicação BMG agora deve funcionar!"
    echo "   Teste fazendo uma nova extração BMG"
else
    echo ""
    echo "❌ Ainda há problemas. Verifique os logs acima."
fi 