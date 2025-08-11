#!/bin/bash

echo "🔧 Habilitando APIs Necessárias para Impersonação"
echo "================================================"

PROJECT_ID="stable-chain-455617-v1"

echo "📋 Habilitando APIs no projeto: $PROJECT_ID"
echo ""

# Verificar se está autenticado
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
    echo "❌ Você precisa estar autenticado primeiro!"
    echo "💡 Execute: gcloud auth login --no-launch-browser"
    exit 1
fi

# Configurar projeto
gcloud config set project $PROJECT_ID

# APIs necessárias para impersonação e Vision
APIS=(
    "iamcredentials.googleapis.com"     # Para impersonação de Service Account
    "vision.googleapis.com"             # Para Google Cloud Vision API
    "cloudresourcemanager.googleapis.com"  # Para gerenciamento de recursos
    "serviceusage.googleapis.com"       # Para uso de serviços
)

echo "🔧 Habilitando APIs essenciais..."

for api in "${APIS[@]}"; do
    echo "   📡 Habilitando: $api"
    gcloud services enable $api --quiet
    
    if [ $? -eq 0 ]; then
        echo "   ✅ $api habilitada"
    else
        echo "   ⚠️ Erro ao habilitar $api (pode já estar habilitada)"
    fi
done

echo ""
echo "⏳ Aguardando propagação das APIs (30 segundos)..."
echo "   As APIs podem levar alguns minutos para ficarem totalmente ativas."
sleep 30

echo ""
echo "✅ APIs habilitadas! Agora testando..."

# Testar se a impersonação funciona agora
python /app/test_impersonation.py

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCESSO TOTAL!"
    echo "=================="
    echo ""
    echo "✅ Todas as APIs habilitadas"
    echo "✅ Impersonação funcionando"
    echo "✅ Google Cloud Vision API testada"
    echo ""
    echo "🚀 Configuração completa! Agora você pode usar:"
    echo "   python main.py"
    echo ""
    echo "💡 Para futuras sessões:"
    echo "   source /app/gcloud-config/activate_impersonation.sh"
else
    echo ""
    echo "⚠️ APIs habilitadas, mas ainda há problemas."
    echo "💡 Pode levar alguns minutos para as APIs ficarem totalmente ativas."
    echo ""
    echo "🔄 Tente novamente em alguns minutos:"
    echo "   python /app/test_impersonation.py"
    echo ""
    echo "📞 Ou use a solução simples imediatamente:"
    echo "   ./fix_current_auth.sh"
fi

echo ""
echo "📋 Status das APIs:"
gcloud services list --enabled --filter="name:(iamcredentials.googleapis.com OR vision.googleapis.com)" --format="table(name,title)" 