#!/usr/bin/env python3
"""
Teste muito simples da Google Cloud Vision API
Apenas verifica se consegue criar o cliente
"""

import os
import sys
from google.cloud import vision

# Configurar variáveis de ambiente
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/root/.config/gcloud/application_default_credentials.json'
os.environ['GOOGLE_CLOUD_PROJECT'] = 'stable-chain-455617-v1'

print("🔍 Teste Simples da Google Cloud Vision")
print("=" * 50)

print(f"📋 Ambiente:")
print(f"   GOOGLE_APPLICATION_CREDENTIALS: {os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')}")
print(f"   GOOGLE_CLOUD_PROJECT: {os.environ.get('GOOGLE_CLOUD_PROJECT')}")

try:
    print("\n🧪 Tentando criar cliente Vision...")
    client = vision.ImageAnnotatorClient()
    print("✅ SUCESSO! Cliente Vision criado com sucesso!")
    
    print("\n🔍 Informações do cliente:")
    print(f"   Tipo: {type(client)}")
    print(f"   Cliente válido: {client is not None}")
    
    print("\n🎉 RESULTADO: Credenciais estão funcionando perfeitamente!")
    print("   Sua aplicação pode usar a Google Cloud Vision API!")
    
    sys.exit(0)
    
except Exception as e:
    print(f"\n❌ ERRO: {e}")
    print(f"   Tipo do erro: {type(e)}")
    sys.exit(1) 