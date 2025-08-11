#!/usr/bin/env python3

import os
from google.cloud import vision

# Configurar variáveis de ambiente
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/root/.config/gcloud/application_default_credentials.json'
os.environ['GOOGLE_CLOUD_PROJECT'] = 'stable-chain-455617-v1'

print("🔧 Configurações:")
print(f"   GOOGLE_APPLICATION_CREDENTIALS: {os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')}")
print(f"   GOOGLE_CLOUD_PROJECT: {os.environ.get('GOOGLE_CLOUD_PROJECT')}")

try:
    print("\n🧪 Testando Google Cloud Vision API...")
    client = vision.ImageAnnotatorClient()
    print("✅ Cliente criado!")
    
    # Teste com imagem vazia (mínimo)
    image = vision.Image()
    response = client.text_detection(image=image)
    
    if response.error.message:
        print(f"❌ Erro da API: {response.error.message}")
    else:
        print("✅ API funcionando! Teste concluído com sucesso.")
        
except Exception as e:
    print(f"❌ Erro: {e}")
    print(f"   Tipo: {type(e)}") 