#!/bin/bash

echo "🚀 Testando Aplicação Principal - PDF OCR API"
echo "============================================="

PROJECT_ID="stable-chain-455617-v1"

# Configurar ambiente
echo "🔧 Configurando ambiente..."
source /app/gcloud-config/activate_credentials.sh 2>/dev/null || true

# Configurar variáveis manualmente se necessário
export GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json"
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"

echo ""
echo "📋 Configuração atual:"
echo "   GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"
echo "   GOOGLE_CLOUD_PROJECT: $GOOGLE_CLOUD_PROJECT"
echo "   Projeto gcloud: $(gcloud config get-value project 2>/dev/null)"
echo ""

# Verificar se arquivo de credenciais existe
if [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "❌ Arquivo de credenciais não encontrado!"
    exit 1
fi

echo "✅ Arquivo de credenciais encontrado"

# Teste rápido das credenciais
echo ""
echo "🧪 Testando credenciais rapidamente..."
python3 -c "
import os
from google.cloud import vision

try:
    client = vision.ImageAnnotatorClient()
    print('✅ Cliente Vision criado com sucesso!')
    print('✅ Credenciais estão funcionando!')
except Exception as e:
    print(f'❌ Erro: {e}')
    exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ Problema com credenciais"
    exit 1
fi

echo ""
echo "🚀 Iniciando aplicação principal..."
echo "   Pressione Ctrl+C para parar o servidor"
echo ""

# Iniciar a aplicação
python main.py 