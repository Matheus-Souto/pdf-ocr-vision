#!/bin/bash

echo "🤖 Configuração Completa de Impersonação"
echo "========================================"

PROJECT_ID="stable-chain-455617-v1"
SERVICE_ACCOUNT_EMAIL="pdf-ocr-vision-sa@stable-chain-455617-v1.iam.gserviceaccount.com"
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"

echo "📋 Configurando base para impersonação..."
echo "   Projeto: $PROJECT_ID"
echo "   Service Account: $SERVICE_ACCOUNT_EMAIL"
echo ""

# Verificar se está autenticado
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
    echo "❌ Você precisa estar autenticado primeiro!"
    echo "💡 Execute: gcloud auth login --no-launch-browser"
    exit 1
fi

CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
echo "✅ Conta autenticada: $CURRENT_ACCOUNT"

# Configurar projeto
gcloud config set project $PROJECT_ID

# Etapa 1: Configurar Application Default Credentials (base para impersonação)
echo ""
echo "🔧 Etapa 1: Configurando Application Default Credentials..."
echo "⚠️ Estas credenciais são necessárias como 'fonte' para a impersonação"
echo ""

gcloud auth application-default login --no-launch-browser

if [ $? -ne 0 ]; then
    echo "❌ Falha ao configurar Application Default Credentials"
    exit 1
fi

echo "✅ Application Default Credentials configuradas!"

# Etapa 2: Configurar impersonação
echo ""
echo "🎭 Etapa 2: Ativando impersonação da Service Account..."
gcloud config set auth/impersonate_service_account $SERVICE_ACCOUNT_EMAIL

# Etapa 3: Salvar configuração no volume
echo ""
echo "💾 Etapa 3: Salvando no volume persistente..."
cp -r "$GCLOUD_CONFIG_DIR"/* "$VOLUME_CONFIG_DIR/" 2>/dev/null || true

# Etapa 4: Criar script de ativação
echo ""
echo "📄 Etapa 4: Criando scripts de ativação..."

# Script para carregar impersonação
cat > /app/gcloud-config/activate_impersonation.sh << EOF
#!/bin/bash
# Ativação de impersonação de Service Account

PROJECT_ID="$PROJECT_ID"
SERVICE_ACCOUNT_EMAIL="$SERVICE_ACCOUNT_EMAIL"

# Restaurar configuração do gcloud
if [ -d "/app/gcloud-config" ]; then
    cp -r /app/gcloud-config/* /root/.config/gcloud/ 2>/dev/null || true
fi

# Configurar projeto e impersonação
gcloud config set project \$PROJECT_ID
gcloud config set auth/impersonate_service_account \$SERVICE_ACCOUNT_EMAIL

# Configurar variáveis de ambiente
export GOOGLE_CLOUD_PROJECT="\$PROJECT_ID"
export GCLOUD_IMPERSONATE_SERVICE_ACCOUNT="\$SERVICE_ACCOUNT_EMAIL"

echo "✅ Impersonação ativada:"
echo "   Projeto: \$PROJECT_ID"
echo "   Service Account: \$SERVICE_ACCOUNT_EMAIL"
echo "   Conta base: \$(gcloud config get-value account)"
EOF

chmod +x /app/gcloud-config/activate_impersonation.sh

# Script de teste com impersonação
cat > /app/test_impersonation.py << 'EOF'
#!/usr/bin/env python3
"""
Teste específico para impersonação de Service Account
"""

import os
from google.cloud import vision
from google.auth import impersonated_credentials
from google.auth import default

def test_impersonation():
    """Testa impersonação de Service Account"""
    print("🧪 Testando impersonação de Service Account...")
    
    try:
        # Obter credenciais base (Application Default)
        source_credentials, project = default()
        print(f"✅ Credenciais base obtidas para projeto: {project}")
        
        # Configurar impersonação
        service_account = os.getenv('GCLOUD_IMPERSONATE_SERVICE_ACCOUNT')
        if not service_account:
            service_account = "pdf-ocr-vision-sa@stable-chain-455617-v1.iam.gserviceaccount.com"
        
        print(f"🎭 Impersonando: {service_account}")
        
        target_credentials = impersonated_credentials.Credentials(
            source_credentials=source_credentials,
            target_principal=service_account,
            target_scopes=['https://www.googleapis.com/auth/cloud-platform']
        )
        
        # Criar cliente Vision com credenciais impersonadas
        client = vision.ImageAnnotatorClient(credentials=target_credentials)
        print("✅ Cliente Vision criado com impersonação!")
        
        # Teste mínimo da API
        image = vision.Image()
        response = client.text_detection(image=image)
        
        if response.error.message:
            print(f"❌ Erro da API: {response.error.message}")
            return False
        
        print("✅ API Vision funcionando com impersonação!")
        return True
        
    except Exception as e:
        print(f"❌ Erro na impersonação: {e}")
        print(f"   Tipo: {type(e)}")
        return False

if __name__ == "__main__":
    print("🚀 Teste de Impersonação Google Cloud Vision")
    print("=" * 50)
    
    # Configurar variáveis
    os.environ['GOOGLE_CLOUD_PROJECT'] = 'stable-chain-455617-v1'
    os.environ['GCLOUD_IMPERSONATE_SERVICE_ACCOUNT'] = 'pdf-ocr-vision-sa@stable-chain-455617-v1.iam.gserviceaccount.com'
    
    if test_impersonation():
        print("\n🎉 SUCESSO: Impersonação funcionando perfeitamente!")
        exit(0)
    else:
        print("\n❌ FALHA: Problema com impersonação")
        exit(1)
EOF

chmod +x /app/test_impersonation.py

# Etapa 5: Testar configuração completa
echo ""
echo "🧪 Etapa 5: Testando configuração completa..."

# Configurar variáveis de ambiente
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
export GCLOUD_IMPERSONATE_SERVICE_ACCOUNT="$SERVICE_ACCOUNT_EMAIL"

# Executar teste
python /app/test_impersonation.py

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 CONFIGURAÇÃO COMPLETA E FUNCIONANDO!"
    echo "======================================"
    echo ""
    echo "✅ Application Default Credentials configuradas"
    echo "✅ Service Account configurada"
    echo "✅ Impersonação ativada"
    echo "✅ Google Cloud Vision API testada"
    echo "✅ Configuração salva no volume persistente"
    echo ""
    echo "📋 Para usar em futuras sessões:"
    echo "   source /app/gcloud-config/activate_impersonation.sh"
    echo ""
    echo "🚀 Para testar novamente:"
    echo "   python /app/test_impersonation.py"
    echo ""
    echo "💡 Esta configuração:"
    echo "   ✅ Não expira (Service Account)"
    echo "   ✅ Respeita políticas organizacionais"
    echo "   ✅ Audit trail completo"
    echo "   ✅ Funciona indefinidamente"
    
    # Adicionar ao bashrc
    if ! grep -q "source /app/gcloud-config/activate_impersonation.sh" ~/.bashrc 2>/dev/null; then
        echo "source /app/gcloud-config/activate_impersonation.sh" >> ~/.bashrc
        echo "✅ Configuração adicionada ao .bashrc"
    fi
    
else
    echo ""
    echo "❌ Ainda há problemas. Diagnóstico:"
    echo "   Conta ativa: $(gcloud config get-value account)"
    echo "   Projeto: $(gcloud config get-value project)"
    echo "   Impersonação: $(gcloud config get-value auth/impersonate_service_account)"
    echo ""
    echo "💡 Tente novamente ou use a solução simples:"
    echo "   ./fix_current_auth.sh"
fi 