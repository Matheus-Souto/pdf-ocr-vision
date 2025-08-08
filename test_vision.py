"""
Script de teste para diagnosticar problemas com Google Cloud Vision
"""

import os
from google.cloud import vision
from google.auth.exceptions import DefaultCredentialsError

def test_vision_credentials():
    """Testa as credenciais do Google Cloud Vision"""
    print("🔍 Testando credenciais do Google Cloud Vision...")
    
    try:
        # Tentar criar cliente
        client = vision.ImageAnnotatorClient()
        print("✅ Cliente criado com sucesso!")
        
        # Testar com imagem vazia para ver se a API responde
        image = vision.Image()
        response = client.text_detection(image=image)
        
        print("✅ API respondeu (mesmo com imagem vazia)")
        return True
        
    except DefaultCredentialsError as e:
        print(f"❌ Erro de credenciais: {e}")
        print("\n💡 Soluções:")
        print("1. Instalar Google Cloud CLI: https://cloud.google.com/sdk/docs/install")
        print("2. Executar: gcloud auth application-default login")
        print("3. Ou usar conta pessoal do Google")
        return False
        
    except Exception as e:
        print(f"❌ Erro inesperado: {e}")
        print(f"Tipo do erro: {type(e)}")
        return False

def test_environment():
    """Testa as variáveis de ambiente"""
    print("\n🔧 Verificando variáveis de ambiente...")
    
    credentials = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if credentials:
        print(f"GOOGLE_APPLICATION_CREDENTIALS: {credentials}")
        if os.path.exists(credentials):
            print("✅ Arquivo de credenciais existe")
        else:
            print("❌ Arquivo de credenciais não encontrado")
    else:
        print("GOOGLE_APPLICATION_CREDENTIALS: Não definida")
        print("💡 Tentará usar Application Default Credentials")

if __name__ == "__main__":
    print("🚀 Diagnóstico do Google Cloud Vision")
    print("=" * 50)
    
    test_environment()
    test_vision_credentials()
    
    print("\n" + "=" * 50)
    print("✨ Diagnóstico concluído!") 