#!/bin/bash

echo "🔧 Correção Rápida da Autenticação Atual"
echo "========================================"

PROJECT_ID="stable-chain-455617-v1"
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"

echo "💡 Esta é a solução mais simples para o seu caso!"
echo "   Vai renovar as Application Default Credentials que você já tem."
echo ""

# Verificar se gcloud está autenticado
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
    echo "❌ Você precisa estar autenticado no gcloud primeiro!"
    echo "💡 Execute: gcloud auth login --no-launch-browser"
    exit 1
fi

CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
echo "✅ Conta autenticada: $CURRENT_ACCOUNT"

# Configurar projeto
echo "🎯 Configurando projeto..."
gcloud config set project $PROJECT_ID

# Renovar Application Default Credentials
echo ""
echo "🔄 Renovando Application Default Credentials..."
echo "⚠️ Você precisará autorizar no navegador uma última vez"
echo ""

gcloud auth application-default login --no-launch-browser

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Application Default Credentials renovadas!"
    
    # Salvar no volume persistente
    echo "💾 Salvando no volume persistente..."
    cp -r "$GCLOUD_CONFIG_DIR"/* "$VOLUME_CONFIG_DIR/" 2>/dev/null || true
    
    # Configurar variáveis de ambiente
    export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
    export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
    
    # Criar script de configuração automática
    cat > /app/gcloud-config/load_credentials.sh << EOF
#!/bin/bash
# Carregamento automático das credenciais

export GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json"
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"

echo "✅ Credenciais carregadas:"
echo "   GOOGLE_APPLICATION_CREDENTIALS=\$GOOGLE_APPLICATION_CREDENTIALS"
echo "   GOOGLE_CLOUD_PROJECT=\$GOOGLE_CLOUD_PROJECT"
EOF
    
    chmod +x /app/gcloud-config/load_credentials.sh
    
    # Testar se funciona
    echo ""
    echo "🧪 Testando nova configuração..."
    python test_api_working.py
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 SUCESSO TOTAL!"
        echo "=================="
        echo ""
        echo "✅ Application Default Credentials renovadas e funcionando!"
        echo "✅ Configuração salva no volume persistente"
        echo "✅ Google Cloud Vision API testada e aprovada!"
        echo ""
        echo "📋 Para usar em futuras sessões:"
        echo "   source /app/gcloud-config/load_credentials.sh"
        echo ""
        echo "🚀 Agora você pode executar:"
        echo "   python main.py"
        echo ""
        echo "💡 Esta configuração deve durar várias semanas/meses sem precisar renovar!"
        
        # Adicionar ao bashrc para carregar automaticamente
        if ! grep -q "source /app/gcloud-config/load_credentials.sh" ~/.bashrc 2>/dev/null; then
            echo "source /app/gcloud-config/load_credentials.sh" >> ~/.bashrc
            echo "✅ Configuração adicionada ao .bashrc para carregamento automático"
        fi
        
    else
        echo ""
        echo "❌ Ainda há problemas. Verifique as permissões da conta."
    fi
    
else
    echo ""
    echo "❌ Falha ao renovar credenciais"
    echo "💡 Tente novamente ou use uma conta Google pessoal"
fi 