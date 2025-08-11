#!/bin/bash

echo "🔍 Verificação Rápida de Autenticação"
echo "==================================="

# Verificar status atual da autenticação
echo "📋 Status atual da autenticação gcloud:"
gcloud auth list

echo ""
echo "📋 Configuração atual:"
echo "   Projeto: $(gcloud config get-value project 2>/dev/null || echo 'NÃO CONFIGURADO')"
echo "   Conta: $(gcloud config get-value account 2>/dev/null || echo 'NÃO CONFIGURADO')"

echo ""
echo "💡 Para resolver a autenticação, execute:"
echo "   1. gcloud auth login --no-launch-browser"
echo "   2. Depois: ./fix_current_auth.sh (solução mais simples)"
echo "   3. Ou: ./setup_service_account_alt.sh (solução avançada)" 