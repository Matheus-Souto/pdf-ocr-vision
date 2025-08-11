#!/bin/bash
set -e

echo "🚀 Docker Entrypoint - Configurando Google Cloud..."

# Definir diretórios
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"
PROJECT_ID="stable-chain-455617-v1"

# Criar diretório de configuração do gcloud se não existir
mkdir -p "$GCLOUD_CONFIG_DIR"

# Função para configurar automaticamente
auto_configure() {
    # Prioridade 1: Service Account (mais estável)
    if [ -f "$VOLUME_CONFIG_DIR/service-account-key.json" ]; then
        echo "🤖 Usando Service Account (autenticação automática)"
        export GOOGLE_APPLICATION_CREDENTIALS="$VOLUME_CONFIG_DIR/service-account-key.json"
        export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
        
        # Carregar variáveis se existir arquivo
        if [ -f "$VOLUME_CONFIG_DIR/env_vars.sh" ]; then
            source "$VOLUME_CONFIG_DIR/env_vars.sh"
        fi
        return 0
    fi
    
    # Prioridade 2: Application Default Credentials
    if [ -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
        echo "👤 Usando Application Default Credentials"
        
        # Copiar credenciais do volume para o gcloud config
        cp -r "$VOLUME_CONFIG_DIR"/* "$GCLOUD_CONFIG_DIR/" 2>/dev/null || true
        
        # Definir variável de ambiente
        export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
        export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
        return 0
    fi
    
    echo "⚠️ Nenhuma credencial encontrada no volume"
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
}

# Configurar automaticamente
if auto_configure; then
    if test_credentials; then
        echo "✅ Google Cloud configurado e funcionando!"
    else
        echo "⚠️ Credenciais encontradas mas podem ter expirado"
        echo "💡 Para corrigir: ./fix_auth_persistent.sh"
    fi
else
    echo "💡 Para configurar credenciais:"
    echo "   Service Account (recomendado): ./setup_service_account.sh"
    echo "   Application Default: ./setup_gcloud_persistent.sh"
fi

# Executar comando passado como argumento
echo "🚀 Iniciando aplicação..."
exec "$@" 