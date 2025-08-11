#!/bin/bash

echo "🔧 Configuração Persistente do Google Cloud"
echo "==========================================="

# Verificar se gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI não encontrado!"
    exit 1
fi

# Definir diretórios
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"
PROJECT_ID="stable-chain-455617-v1"

# Criar diretórios se não existirem
mkdir -p "$GCLOUD_CONFIG_DIR"
mkdir -p "$VOLUME_CONFIG_DIR"

# Verificar se já existe configuração no volume
if [ -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
    echo "✅ Credenciais já configuradas no volume!"
    echo "📋 Restaurando e testando configuração existente..."
    
    # Restaurar do volume
    cp -r "$VOLUME_CONFIG_DIR"/* "$GCLOUD_CONFIG_DIR/" 2>/dev/null || true
    export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
    export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
    
    # Configurar projeto
    gcloud config set project $PROJECT_ID
    
    # Testar
    echo "🧪 Testando credenciais existentes..."
    python test_clean.py
    
    # Se o teste falhou, as credenciais podem ter expirado
    if [ $? -ne 0 ]; then
        echo ""
        echo "⚠️ As credenciais existentes parecem ter expirado!"
        echo "💡 Para reautenticar, execute: ./fix_auth_persistent.sh"
        echo "💡 Ou continue com a configuração completa pressionando Enter..."
        read -p "Pressione Enter para continuar ou Ctrl+C para sair..."
    else
        echo "✅ Credenciais funcionando perfeitamente!"
        exit 0
    fi
fi

echo "📋 Passos para configuração PERSISTENTE:"
echo "1. Configurar projeto"
echo "2. Fazer login no Google Cloud"
echo "3. Configurar credenciais padrão"
echo "4. Salvar no volume persistente"
echo ""

# Step 1: Configure project
echo "🎯 Passo 1: Configurando projeto $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Step 2: Login
echo ""
echo "🔐 Passo 2: Login no Google Cloud"
echo "IMPORTANTE: Use uma conta pessoal do Gmail se a organizacional tem restrições"
echo ""
gcloud auth login --no-launch-browser

# Step 3: Set default credentials
echo ""
echo "🎯 Passo 3: Configurar credenciais padrão"
gcloud auth application-default login --no-launch-browser

# Step 4: Save to volume
echo ""
echo "🔍 Passo 4: Salvando no volume persistente..."
if [ -f "$GCLOUD_CONFIG_DIR/application_default_credentials.json" ]; then
    # Copiar TUDO do gcloud config para o volume
    cp -r "$GCLOUD_CONFIG_DIR"/* "$VOLUME_CONFIG_DIR/" 2>/dev/null || true
    
    # Verificar se salvou
    if [ -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
        echo "✅ Credenciais salvas no volume persistente!"
        
        # Configurar variáveis de ambiente
        export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
        export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
        
    else
        echo "❌ Erro ao salvar no volume"
        exit 1
    fi
else
    echo "⚠️ Credenciais não encontradas em $GCLOUD_CONFIG_DIR"
    echo "🔍 Verificando diretório..."
    ls -la "$GCLOUD_CONFIG_DIR"
    exit 1
fi

# Step 5: Test
echo ""
echo "🧪 Passo 5: Testando configuração..."
python test_clean.py

echo ""
echo "✅ Configuração persistente concluída!"
echo "💡 As credenciais foram salvas em: $VOLUME_CONFIG_DIR"
echo "💡 Elas serão restauradas automaticamente na próxima inicialização"
echo "💡 Agora você pode executar: python main.py"

# Listar arquivos salvos no volume
echo ""
echo "📁 Arquivos salvos no volume:"
ls -la "$VOLUME_CONFIG_DIR" 