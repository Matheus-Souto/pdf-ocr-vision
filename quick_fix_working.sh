#!/bin/bash

echo "⚡ Correção Rápida - Usando ADC Existentes"
echo "========================================="

PROJECT_ID="stable-chain-455617-v1"
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"

echo "💡 Você já tem Application Default Credentials configuradas!"
echo "   Vamos apenas configurar para usar diretamente sem impersonação."
echo ""

# Verificar se as credenciais existem
if [ ! -f "$GCLOUD_CONFIG_DIR/application_default_credentials.json" ]; then
    echo "❌ Application Default Credentials não encontradas"
    echo "💡 Execute primeiro: ./complete_impersonation_setup.sh"
    exit 1
fi

echo "✅ Application Default Credentials encontradas"

# Configurar projeto
gcloud config set project $PROJECT_ID

# Remover impersonação para usar credenciais diretas
echo "🔧 Removendo impersonação para usar credenciais diretas..."
gcloud config unset auth/impersonate_service_account

# Configurar variáveis de ambiente
export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"

# Criar script de configuração simples
cat > /app/gcloud-config/simple_credentials.sh << EOF
#!/bin/bash
# Configuração simples usando Application Default Credentials

PROJECT_ID="$PROJECT_ID"

# Restaurar configuração do gcloud se necessário
if [ -d "/app/gcloud-config" ]; then
    cp -r /app/gcloud-config/* /root/.config/gcloud/ 2>/dev/null || true
fi

# Configurar projeto
gcloud config set project \$PROJECT_ID 2>/dev/null

# Remover qualquer impersonação
gcloud config unset auth/impersonate_service_account 2>/dev/null

# Configurar variáveis de ambiente
export GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json"
export GOOGLE_CLOUD_PROJECT="\$PROJECT_ID"

echo "✅ Credenciais simples carregadas:"
echo "   GOOGLE_APPLICATION_CREDENTIALS=\$GOOGLE_APPLICATION_CREDENTIALS"
echo "   GOOGLE_CLOUD_PROJECT=\$GOOGLE_CLOUD_PROJECT"
echo "   Projeto gcloud: \$(gcloud config get-value project 2>/dev/null)"
EOF

chmod +x /app/gcloud-config/simple_credentials.sh

# Salvar no volume
echo "💾 Salvando no volume persistente..."
cp -r "$GCLOUD_CONFIG_DIR"/* "$VOLUME_CONFIG_DIR/" 2>/dev/null || true

# Testar funcionamento
echo ""
echo "🧪 Testando configuração simples..."
python test_api_working.py

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 FUNCIONANDO PERFEITAMENTE!"
    echo "============================="
    echo ""
    echo "✅ Application Default Credentials funcionando"
    echo "✅ Google Cloud Vision API testada"
    echo "✅ Configuração salva no volume persistente"
    echo ""
    echo "📋 Para usar em futuras sessões:"
    echo "   source /app/gcloud-config/simple_credentials.sh"
    echo ""
    echo "🚀 Agora você pode executar:"
    echo "   python main.py"
    echo ""
    echo "💡 Esta configuração:"
    echo "   ✅ É simples e direta"
    echo "   ✅ Funciona imediatamente"
    echo "   ✅ Dura várias semanas/meses"
    echo "   ✅ Compatível com políticas organizacionais"
    
    # Adicionar ao bashrc
    if ! grep -q "source /app/gcloud-config/simple_credentials.sh" ~/.bashrc 2>/dev/null; then
        echo "source /app/gcloud-config/simple_credentials.sh" >> ~/.bashrc
        echo "✅ Configuração adicionada ao .bashrc"
    fi
    
else
    echo ""
    echo "❌ Ainda há problemas. Vamos tentar habilitar as APIs:"
    echo "   ./enable_required_apis.sh"
fi 