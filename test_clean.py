"""
Teste limpo do Google Cloud Vision sem variáveis de ambiente
"""

import os
from google.cloud import vision
from google.auth.exceptions import DefaultCredentialsError

# Forçar remoção de qualquer variável de credencial
if 'GOOGLE_APPLICATION_CREDENTIALS' in os.environ:
    del os.environ['GOOGLE_APPLICATION_CREDENTIALS']
    print("🗑️ Removida variável GOOGLE_APPLICATION_CREDENTIALS")

print("🔍 Verificando variáveis de ambiente após limpeza...")
print(f"GOOGLE_APPLICATION_CREDENTIALS: {os.getenv('GOOGLE_APPLICATION_CREDENTIALS', 'NÃO DEFINIDA')}")

print("\n🧪 Testando Google Cloud Vision sem credenciais...")

try:
    # Tentar criar cliente sem credenciais
    client = vision.ImageAnnotatorClient()
    print("✅ Cliente criado com sucesso!")
    
    # Teste simples
    image = vision.Image()
    response = client.text_detection(image=image)
    
    print("✅ API respondeu (usando Application Default Credentials)")
    
except DefaultCredentialsError as e:
    print(f"❌ Erro de credenciais: {e}")
    print("\n💡 Para resolver:")
    print("1. Instale Google Cloud CLI: https://cloud.google.com/sdk/docs/install")
    print("2. Execute: gcloud auth application-default login")
    
except Exception as e:
    print(f"❌ Erro: {e}")
    print(f"Tipo: {type(e)}") 