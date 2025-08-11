#!/bin/bash

echo "🔍 Verificação de Status de Autenticação Google Cloud"
echo "===================================================="

# Definir diretórios
GCLOUD_CONFIG_DIR="/root/.config/gcloud"
VOLUME_CONFIG_DIR="/app/gcloud-config"
PROJECT_ID="stable-chain-455617-v1"

# Verificar instalação do gcloud
echo "📦 Verificando instalação do Google Cloud CLI..."
if command -v gcloud &> /dev/null; then
    GCLOUD_VERSION=$(gcloud version --format="value(Google Cloud SDK)")
    echo "✅ Google Cloud CLI instalado - Versão: $GCLOUD_VERSION"
else
    echo "❌ Google Cloud CLI não encontrado!"
    exit 1
fi

# Verificar arquivos de credenciais
echo ""
echo "📁 Verificando arquivos de credenciais..."

echo "   Volume persistente ($VOLUME_CONFIG_DIR):"
if [ -d "$VOLUME_CONFIG_DIR" ]; then
    if [ -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
        echo "   ✅ application_default_credentials.json encontrado"
    else
        echo "   ❌ application_default_credentials.json NÃO encontrado"
    fi
    
    if [ -f "$VOLUME_CONFIG_DIR/configurations/config_default" ]; then
        echo "   ✅ configurações do gcloud encontradas"
    else
        echo "   ❌ configurações do gcloud NÃO encontradas"
    fi
else
    echo "   ❌ Diretório do volume não existe"
fi

echo ""
echo "   Diretório local ($GCLOUD_CONFIG_DIR):"
if [ -d "$GCLOUD_CONFIG_DIR" ]; then
    if [ -f "$GCLOUD_CONFIG_DIR/application_default_credentials.json" ]; then
        echo "   ✅ application_default_credentials.json encontrado"
    else
        echo "   ❌ application_default_credentials.json NÃO encontrado"
    fi
    
    if [ -f "$GCLOUD_CONFIG_DIR/configurations/config_default" ]; then
        echo "   ✅ configurações do gcloud encontradas"
    else
        echo "   ❌ configurações do gcloud NÃO encontradas"
    fi
else
    echo "   ❌ Diretório local não existe"
fi

# Verificar variáveis de ambiente
echo ""
echo "🌍 Verificando variáveis de ambiente..."
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "   GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"
    if [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        echo "   ✅ Arquivo existe"
    else
        echo "   ❌ Arquivo não existe"
    fi
else
    echo "   GOOGLE_APPLICATION_CREDENTIALS: NÃO DEFINIDA"
    echo "   💡 Usará Application Default Credentials"
fi

if [ -n "$GOOGLE_CLOUD_PROJECT" ]; then
    echo "   GOOGLE_CLOUD_PROJECT: $GOOGLE_CLOUD_PROJECT"
else
    echo "   GOOGLE_CLOUD_PROJECT: NÃO DEFINIDA"
fi

# Verificar configuração do gcloud
echo ""
echo "⚙️ Verificando configuração do gcloud..."

# Verificar projeto ativo
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ -n "$CURRENT_PROJECT" ]; then
    echo "   Projeto ativo: $CURRENT_PROJECT"
    if [ "$CURRENT_PROJECT" = "$PROJECT_ID" ]; then
        echo "   ✅ Projeto correto configurado"
    else
        echo "   ⚠️ Projeto diferente do esperado ($PROJECT_ID)"
    fi
else
    echo "   ❌ Nenhum projeto configurado"
fi

# Verificar conta ativa
CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
if [ -n "$CURRENT_ACCOUNT" ]; then
    echo "   Conta ativa: $CURRENT_ACCOUNT"
else
    echo "   ❌ Nenhuma conta configurada"
fi

# Testar autenticação gcloud
echo ""
echo "🧪 Testando autenticação do gcloud..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
    echo "✅ Autenticação do gcloud funcionando - Conta: $ACTIVE_ACCOUNT"
else
    echo "❌ Problema com autenticação do gcloud"
fi

# Testar Application Default Credentials
echo ""
echo "🧪 Testando Application Default Credentials..."
python3 -c "
import os
from google.cloud import vision
from google.auth.exceptions import DefaultCredentialsError

try:
    client = vision.ImageAnnotatorClient()
    print('✅ Application Default Credentials funcionando')
except DefaultCredentialsError as e:
    print(f'❌ Erro com Application Default Credentials: {e}')
except Exception as e:
    print(f'❌ Erro inesperado: {e}')
    print(f'   Tipo: {type(e)}')
"

echo ""
echo "📋 Resumo do diagnóstico:"
echo "========================"

# Resumir problemas encontrados
PROBLEMS=0

if [ ! -f "$VOLUME_CONFIG_DIR/application_default_credentials.json" ]; then
    echo "❌ Credenciais não encontradas no volume persistente"
    PROBLEMS=$((PROBLEMS + 1))
fi

if [ ! -f "$GCLOUD_CONFIG_DIR/application_default_credentials.json" ]; then
    echo "❌ Credenciais não encontradas no diretório local"
    PROBLEMS=$((PROBLEMS + 1))
fi

if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "❌ Projeto incorreto ou não configurado"
    PROBLEMS=$((PROBLEMS + 1))
fi

if [ -z "$CURRENT_ACCOUNT" ]; then
    echo "❌ Nenhuma conta autenticada no gcloud"
    PROBLEMS=$((PROBLEMS + 1))
fi

if [ $PROBLEMS -eq 0 ]; then
    echo "✅ Nenhum problema óbvio detectado"
    echo "💡 Se ainda há problemas, as credenciais podem ter expirado"
    echo "💡 Execute: ./fix_auth_persistent.sh"
else
    echo "⚠️ $PROBLEMS problema(s) detectado(s)"
    echo ""
    echo "💡 Soluções recomendadas:"
    echo "   1. Se nunca configurou: ./setup_gcloud_persistent.sh"
    echo "   2. Se já configurou antes: ./fix_auth_persistent.sh"
fi 