#!/bin/bash

echo "🔧 Configuração Persistente do Google Cloud"
echo "==========================================="

# Verificar se gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI não encontrado!"
    exit 1
fi

# Verificar se o diretório de credenciais existe
CRED_DIR="/app/credentials"
if [ ! -d "$CRED_DIR" ]; then
    echo "📁 Criando diretório de credenciais..."
    mkdir -p "$CRED_DIR"
fi

# Verificar se já existe configuração
if [ -f "$CRED_DIR/application_default_credentials.json" ]; then
    echo "✅ Credenciais já configuradas!"
    echo "📋 Testando configuração existente..."
    python test_clean.py
    exit 0
fi

echo "📋 Passos para configuração PERSISTENTE:"
echo "1. Fazer login no Google Cloud"
echo "2. Configurar credenciais padrão"
echo "3. Salvar no volume persistente"
echo ""

# Step 1: Login
echo "🔐 Passo 1: Login no Google Cloud"
echo "IMPORTANTE: Use uma conta pessoal do Gmail se a organizacional tem restrições"
echo ""
gcloud auth login --no-launch-browser

# Step 2: Set default credentials
echo ""
echo "🎯 Passo 2: Configurar credenciais padrão"
gcloud auth application-default login --no-launch-browser

# Step 3: Verificar se as credenciais foram salvas no volume
echo ""
echo "🔍 Passo 3: Verificando persistência..."
if [ -f "/root/.config/gcloud/application_default_credentials.json" ]; then
    # Copiar para o volume persistente se necessário
    cp /root/.config/gcloud/application_default_credentials.json "$CRED_DIR/"
    cp -r /root/.config/gcloud/* "$CRED_DIR/" 2>/dev/null || true
    echo "✅ Credenciais salvas no volume persistente!"
else
    echo "⚠️ Credenciais não encontradas, verifique a configuração"
fi

# Step 4: Test
echo ""
echo "🧪 Passo 4: Testando configuração..."
python test_clean.py

echo ""
echo "✅ Configuração persistente concluída!"
echo "💡 As credenciais serão mantidas mesmo após restart do container"
echo "💡 Agora você pode executar: python main.py" 