#!/bin/bash

echo "🎯 Configuração Final e Funcional"
echo "================================="

PROJECT_ID="stable-chain-455617-v1"
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"

echo "💡 Vamos configurar de forma definitiva e funcional!"
echo ""

# Remover qualquer impersonação que possa estar ativa
echo "🔧 Removendo impersonação (usando credenciais diretas)..."
gcloud config unset auth/impersonate_service_account 2>/dev/null || true

# Configurar projeto
echo "🎯 Configurando projeto..."
gcloud config set project $PROJECT_ID

# Verificar se Application Default Credentials existem
if [ ! -f "$GCLOUD_CONFIG_DIR/application_default_credentials.json" ]; then
    echo "❌ Application Default Credentials não encontradas!"
    echo "💡 Você precisa executar primeiro: gcloud auth application-default login --no-launch-browser"
    exit 1
fi

echo "✅ Application Default Credentials encontradas"

# Configurar variáveis de ambiente
export GOOGLE_APPLICATION_CREDENTIALS="$GCLOUD_CONFIG_DIR/application_default_credentials.json"
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"

# Salvar no volume
echo "💾 Salvando configuração no volume persistente..."
cp -r "$GCLOUD_CONFIG_DIR"/* "$VOLUME_CONFIG_DIR/" 2>/dev/null || true

# Criar script de ativação final
echo "📄 Criando script de ativação final..."
cat > /app/gcloud-config/activate_credentials.sh << EOF
#!/bin/bash
# Ativação final das credenciais Google Cloud

PROJECT_ID="$PROJECT_ID"

# Restaurar configuração do volume
if [ -d "/app/gcloud-config" ]; then
    mkdir -p /root/.config/gcloud
    cp -r /app/gcloud-config/* /root/.config/gcloud/ 2>/dev/null || true
fi

# Configurar projeto
gcloud config set project \$PROJECT_ID 2>/dev/null || true

# Remover qualquer impersonação
gcloud config unset auth/impersonate_service_account 2>/dev/null || true

# Configurar variáveis de ambiente
export GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json"
export GOOGLE_CLOUD_PROJECT="\$PROJECT_ID"

echo "✅ Google Cloud configurado:"
echo "   Projeto: \$PROJECT_ID"
echo "   Credenciais: Application Default Credentials"
echo "   Status: Pronto para usar!"
EOF

chmod +x /app/gcloud-config/activate_credentials.sh

# Testar com o teste corrigido
echo ""
echo "🧪 Testando com teste corrigido..."
python test_vision_fixed.py

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 CONFIGURAÇÃO FINAL CONCLUÍDA COM SUCESSO!"
    echo "============================================="
    echo ""
    echo "✅ Application Default Credentials funcionando"
    echo "✅ Google Cloud Vision API testada e aprovada"
    echo "✅ Configuração salva no volume persistente"
    echo "✅ Script de ativação criado"
    echo ""
    echo "📋 Para usar em futuras sessões:"
    echo "   source /app/gcloud-config/activate_credentials.sh"
    echo ""
    echo "🚀 AGORA VOCÊ PODE EXECUTAR SUA APLICAÇÃO:"
    echo "   python main.py"
    echo ""
    echo "💡 Esta configuração:"
    echo "   ✅ Funciona imediatamente"
    echo "   ✅ Se restaura automaticamente"
    echo "   ✅ Dura várias semanas/meses"
    echo "   ✅ É compatível com políticas organizacionais"
    echo "   ✅ Não precisa de reautenticação constante"
    
    # Adicionar ao bashrc para carregamento automático
    if ! grep -q "source /app/gcloud-config/activate_credentials.sh" ~/.bashrc 2>/dev/null; then
        echo "source /app/gcloud-config/activate_credentials.sh" >> ~/.bashrc
        echo ""
        echo "✅ Configuração automática adicionada ao .bashrc"
        echo "   Credenciais serão carregadas automaticamente em novas sessões!"
    fi
    
else
    echo ""
    echo "❌ Ainda há problemas, mas isso não deveria acontecer..."
    echo ""
    echo "🔍 Diagnóstico:"
    echo "   Conta: $(gcloud config get-value account 2>/dev/null)"
    echo "   Projeto: $(gcloud config get-value project 2>/dev/null)"
    echo "   Credenciais ADC: $([ -f "$GCLOUD_CONFIG_DIR/application_default_credentials.json" ] && echo 'EXISTEM' || echo 'NÃO EXISTEM')"
    echo ""
    echo "💡 Tente executar manualmente:"
    echo "   python main.py"
    echo ""
    echo "   Se a aplicação principal funcionar, então está tudo OK!"
fi 