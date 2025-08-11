#!/bin/bash

echo "🚀 Configuração Automática do Google Cloud"
echo "=========================================="

PROJECT_ID="stable-chain-455617-v1"
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"

# Função para configurar variáveis de ambiente
setup_env_vars() {
    # Verificar se existe Service Account
    if [ -f "$VOLUME_CONFIG_DIR/service-account-key.json" ]; then
        echo "🤖 Usando Service Account (autenticação automática)"
        export GOOGLE_APPLICATION_CREDENTIALS="$VOLUME_CONFIG_DIR/service-account-key.json"
        export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
        return 0
    fi
    
    # Verificar se existem Application Default Credentials
    if [ -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
        echo "👤 Usando Application Default Credentials"
        # Restaurar configuração
        cp -r "$VOLUME_CONFIG_DIR"/* "$GCLOUD_CONFIG_DIR/" 2>/dev/null || true
        export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
        export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
        return 0
    fi
    
    echo "❌ Nenhuma credencial encontrada"
    return 1
}

# Função para testar credenciais
test_credentials() {
    echo "🧪 Testando credenciais..."
    python3 -c "
import os
from google.cloud import vision
try:
    client = vision.ImageAnnotatorClient()
    image = vision.Image()
    response = client.text_detection(image=image)
    print('✅ Credenciais funcionando!')
    exit(0)
except Exception as e:
    print(f'❌ Erro: {e}')
    exit(1)
" 2>/dev/null
    
    return $?
}

# Configurar projeto gcloud se possível
if command -v gcloud &> /dev/null; then
    gcloud config set project $PROJECT_ID 2>/dev/null || true
fi

# Tentar configurar credenciais
if setup_env_vars; then
    if test_credentials; then
        echo "✅ SUCESSO: Google Cloud configurado e funcionando!"
        
        # Salvar configuração no bashrc para sessões futuras
        if ! grep -q "source /app/gcloud-config/env_vars.sh" ~/.bashrc 2>/dev/null; then
            if [ -f "/app/gcloud-config/env_vars.sh" ]; then
                echo "source /app/gcloud-config/env_vars.sh" >> ~/.bashrc
                echo "💡 Configuração adicionada ao .bashrc para carregamento automático"
            fi
        fi
        
        echo ""
        echo "📋 Configuração atual:"
        echo "   GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"
        echo "   GOOGLE_CLOUD_PROJECT: $GOOGLE_CLOUD_PROJECT"
        echo ""
        echo "🚀 Pronto para usar! Execute: python main.py"
        exit 0
    else
        echo "⚠️ Credenciais encontradas mas não funcionando"
        
        # Se são Application Default Credentials, podem ter expirado
        if [ -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
            echo "💡 As credenciais podem ter expirado. Para corrigir:"
            echo "   ./fix_auth_persistent.sh"
        fi
    fi
else
    echo "💡 Nenhuma credencial configurada. Para configurar:"
    echo ""
    echo "🤖 Opção 1 - Service Account (RECOMENDADO):"
    echo "   chmod +x setup_service_account.sh"
    echo "   ./setup_service_account.sh"
    echo ""
    echo "👤 Opção 2 - Application Default Credentials:"
    echo "   chmod +x setup_gcloud_persistent.sh"
    echo "   ./setup_gcloud_persistent.sh"
fi

echo ""
echo "❌ Configuração automática falhou. Configure manualmente."
exit 1 