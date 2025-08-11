#!/bin/bash

echo "🔧 Correção de Autenticação Google Cloud"
echo "========================================"

# Definir diretórios
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"
PROJECT_ID="stable-chain-455617-v1"

# Verificar se gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI não encontrado!"
    exit 1
fi

echo "🔍 Diagnosticando problema de autenticação..."

# Verificar se existe configuração
if [ ! -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
    echo "❌ Nenhuma credencial encontrada no volume persistente!"
    echo "💡 Execute primeiro: ./setup_gcloud_persistent.sh"
    exit 1
fi

echo "✅ Credenciais encontradas no volume persistente"

# Restaurar configuração do volume
echo "📋 Restaurando configuração do volume..."
cp -r "$VOLUME_CONFIG_DIR"/* "$GCLOUD_CONFIG_DIR/" 2>/dev/null || true

# Verificar se a configuração foi restaurada
if [ -f "$GCLOUD_CONFIG_DIR/application_default_credentials.json" ]; then
    echo "✅ Configuração restaurada"
else
    echo "❌ Erro ao restaurar configuração"
    exit 1
fi

# Configurar projeto
echo "🎯 Configurando projeto $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# Tentar listar projetos para verificar se a auth funciona
echo "🧪 Testando autenticação gcloud atual..."
if gcloud projects list --limit=1 >/dev/null 2>&1; then
    echo "✅ Autenticação gcloud funcionando!"
    
    # Testar credenciais de aplicação
    echo "🧪 Testando Application Default Credentials..."
    export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
    export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
    
    python test_api_working.py
    
    if [ $? -eq 0 ]; then
        echo "✅ API funcionando perfeitamente! Nenhuma correção necessária."
        exit 0
    else
        echo "⚠️ Application Default Credentials precisam ser renovadas"
    fi
else
    echo "⚠️ Problema com autenticação gcloud"
fi

echo "⚠️ Credenciais expiraram ou há problema de permissão"
echo "🔄 Iniciando reautenticação..."

echo ""
echo "📋 Passos para reautenticação:"
echo "1. Login no Google Cloud"
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

# Step 3: Save to volume
echo ""
echo "🔍 Passo 3: Salvando credenciais atualizadas no volume..."
if [ -f "$GCLOUD_CONFIG_DIR/application_default_credentials.json" ]; then
    # Copiar TUDO do gcloud config para o volume
    cp -r "$GCLOUD_CONFIG_DIR"/* "$VOLUME_CONFIG_DIR/" 2>/dev/null || true
    
    # Verificar se salvou
    if [ -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
        echo "✅ Credenciais atualizadas salvas no volume persistente!"
        
        # Configurar variáveis de ambiente
        export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
        export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
        
    else
        echo "❌ Erro ao salvar no volume"
        exit 1
    fi
else
    echo "⚠️ Credenciais não encontradas em $GCLOUD_CONFIG_DIR"
    exit 1
fi

# Step 4: Test
echo ""
echo "🧪 Passo 4: Testando configuração atualizada..."
export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
python test_api_working.py

echo ""
echo "✅ Reautenticação concluída!"
echo "💡 As credenciais foram atualizadas em: $VOLUME_CONFIG_DIR"
echo "💡 Agora você pode executar: python main.py" 