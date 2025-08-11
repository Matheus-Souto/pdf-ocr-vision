#!/bin/bash

echo "🔄 Restaurando Configuração e Corrigindo Autenticação"
echo "===================================================="

PROJECT_ID="stable-chain-455617-v1"
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"

echo "📋 Verificando configuração salva no volume..."

# Verificar se há configuração salva no volume
if [ -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
    echo "✅ Credenciais encontradas no volume!"
    
    # Restaurar do volume
    echo "📥 Restaurando configuração do volume..."
    mkdir -p "$GCLOUD_CONFIG_DIR"
    cp -r "$VOLUME_CONFIG_DIR"/* "$GCLOUD_CONFIG_DIR/" 2>/dev/null || true
    
    # Configurar projeto
    echo "🎯 Configurando projeto..."
    gcloud config set project $PROJECT_ID 2>/dev/null || true
    
    # Remover impersonação (usar credenciais diretas)
    echo "🔧 Configurando para usar credenciais diretas..."
    gcloud config unset auth/impersonate_service_account 2>/dev/null || true
    
    # Configurar variáveis de ambiente
    export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
    export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
    
    echo ""
    echo "🧪 Testando configuração restaurada..."
    python test_api_working.py
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 SUCESSO! Configuração restaurada e funcionando!"
        echo "================================================"
        echo ""
        echo "✅ Credenciais restauradas do volume"
        echo "✅ Google Cloud Vision API funcionando"
        echo "✅ Sem necessidade de reautenticação"
        echo ""
        echo "🚀 Agora você pode executar:"
        echo "   python main.py"
        echo ""
        
        # Criar script de ativação rápida
        cat > /app/quick_activate.sh << 'EOF'
#!/bin/bash
# Ativação rápida das credenciais

PROJECT_ID="stable-chain-455617-v1"

# Restaurar configuração
if [ -d "/app/gcloud-config" ]; then
    cp -r /app/gcloud-config/* /root/.config/gcloud/ 2>/dev/null || true
fi

# Configurar projeto
gcloud config set project $PROJECT_ID 2>/dev/null || true

# Remover impersonação
gcloud config unset auth/impersonate_service_account 2>/dev/null || true

# Variáveis de ambiente
export GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json"
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"

echo "✅ Credenciais ativadas! Execute: python main.py"
EOF
        
        chmod +x /app/quick_activate.sh
        
        # Adicionar ao bashrc
        if ! grep -q "source /app/quick_activate.sh" ~/.bashrc 2>/dev/null; then
            echo "source /app/quick_activate.sh" >> ~/.bashrc
            echo "✅ Ativação automática configurada para futuras sessões"
        fi
        
        exit 0
    else
        echo ""
        echo "⚠️ Credenciais restauradas mas há problemas de API/permissões"
        echo "💡 Vamos tentar reautenticar..."
    fi
else
    echo "❌ Nenhuma configuração encontrada no volume"
    echo "💡 Você precisa configurar pela primeira vez"
fi

echo ""
echo "🔐 Reautenticação necessária..."
echo "Execute os seguintes comandos:"
echo ""
echo "1. Autenticar no gcloud:"
echo "   gcloud auth login --no-launch-browser"
echo ""
echo "2. Depois escolha uma opção:"
echo "   a) Solução simples: ./quick_fix_working.sh"
echo "   b) Solução avançada: ./complete_impersonation_setup.sh"
echo ""
echo "📋 Status atual:"
echo "   Projeto: $(gcloud config get-value project 2>/dev/null || echo 'NÃO CONFIGURADO')"
echo "   Conta: $(gcloud config get-value account 2>/dev/null || echo 'NÃO AUTENTICADO')"
echo "   Credenciais ADC: $([ -f "$GCLOUD_CONFIG_DIR/application_default_credentials.json" ] && echo 'EXISTEM' || echo 'NÃO EXISTEM')" 