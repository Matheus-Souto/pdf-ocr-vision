#!/bin/bash

echo "🔧 Script de Configuração Google Cloud no Docker"
echo "================================================="

# Verificar se gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI não encontrado!"
    exit 1
fi

echo "📋 Passos para configuração:"
echo "1. Fazer login no Google Cloud"
echo "2. Configurar credenciais padrão"
echo "3. Testar a API Vision"
echo ""

# Step 1: Login
echo "🔐 Passo 1: Login no Google Cloud"
echo "IMPORTANTE: Use uma conta pessoal do Gmail se a organizacional tem restrições"
echo ""
gcloud auth login --no-browser

# Step 2: Set default credentials
echo ""
echo "🎯 Passo 2: Configurar credenciais padrão"
gcloud auth application-default login --no-browser

# Step 3: Test
echo ""
echo "🧪 Passo 3: Testando configuração..."
python test_clean.py

echo ""
echo "✅ Configuração concluída!"
echo "💡 Agora você pode executar: python main.py" 