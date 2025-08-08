#!/bin/bash
set -e

echo "🚀 Docker Entrypoint - Configurando Google Cloud..."

# Definir diretórios
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"

# Criar diretório de configuração do gcloud se não existir
mkdir -p "$GCLOUD_CONFIG_DIR"

# Se o volume tem credenciais salvas, usar elas
if [ -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
    echo "✅ Credenciais encontradas no volume - restaurando..."
    
    # Copiar credenciais do volume para o gcloud config
    cp -r "$VOLUME_CONFIG_DIR"/* "$GCLOUD_CONFIG_DIR/" 2>/dev/null || true
    
    # Definir variável de ambiente
    export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
    export GOOGLE_CLOUD_PROJECT="stable-chain-455617-v1"
    
    echo "✅ Credenciais restauradas com sucesso!"
    
    # Testar se funcionam
    echo "🧪 Testando credenciais..."
    python test_clean.py
    
else
    echo "⚠️ Credenciais não encontradas no volume"
    echo "💡 Execute o setup uma vez: ./setup_gcloud_persistent.sh"
fi

# Executar comando passado como argumento
echo "🚀 Iniciando aplicação..."
exec "$@" 