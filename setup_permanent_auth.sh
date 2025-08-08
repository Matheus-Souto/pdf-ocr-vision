#!/bin/bash

echo "🔐 Configuração PERMANENTE do Google Cloud"
echo "=========================================="

# Definir projeto
PROJECT_ID="stable-chain-455617-v1"

echo "🎯 Configurando projeto: $PROJECT_ID"
gcloud config set project $PROJECT_ID

echo "🔐 Fazendo login principal..."
gcloud auth login --no-launch-browser

echo "🎯 Configurando Application Default Credentials..."
gcloud auth application-default login --no-launch-browser

echo "📋 Configurando quota project..."
gcloud auth application-default set-quota-project $PROJECT_ID

echo "🔧 Configurando variáveis de ambiente..."
export GOOGLE_CLOUD_PROJECT=$PROJECT_ID

# Salvar configuração no perfil (Windows)
echo "💾 Salvando configuração permanente..."
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    setx GOOGLE_CLOUD_PROJECT $PROJECT_ID
    echo "✅ Variável GOOGLE_CLOUD_PROJECT salva no Windows"
fi

echo ""
echo "🧪 Testando configuração..."
python test_clean.py

echo ""
echo "📋 RESUMO DA CONFIGURAÇÃO:"
echo "========================="
echo "✅ Projeto configurado: $PROJECT_ID"
echo "✅ Login realizado"
echo "✅ ADC configurado"
echo "✅ Quota project definido"
echo "✅ Variável de ambiente salva"
echo ""
echo "💡 PARA DEPLOY: Use volume persistente ou Service Account Key"
echo "📚 Consulte: DEPLOY_DIGITAL_OCEAN_PERSISTENT.md" 