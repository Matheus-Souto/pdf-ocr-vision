"""
Teste específico para verificar se a Google Cloud Vision API está funcionando
"""

import os
from google.cloud import vision
from google.auth.exceptions import DefaultCredentialsError

def test_vision_api():
    """Testa se a Vision API está realmente funcionando"""
    print("🧪 Testando Google Cloud Vision API...")
    
    try:
        # Criar cliente
        client = vision.ImageAnnotatorClient()
        print("✅ Cliente criado com sucesso!")
        
        # Testar com uma imagem muito simples (1x1 pixel branco)
        # Isso deve retornar sem erro, mesmo que não encontre texto
        image = vision.Image()
        image.content = b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x01\x00\x00\x00\x007n\xf9$\x00\x00\x00\nIDAT\x08\x1dc\xf8\x00\x00\x00\x01\x00\x01U\xaa\xfb!\x00\x00\x00\x00IEND\xaeB`\x82'
        
        response = client.text_detection(image=image)
        
        # Verificar se há erro na resposta
        if response.error.message:
            print(f"❌ Erro na API: {response.error.message}")
            return False
        
        print("✅ API respondeu com sucesso!")
        print(f"📄 Texto encontrado: {len(response.text_annotations)} anotações")
        return True
        
    except DefaultCredentialsError as e:
        print(f"❌ Erro de credenciais: {e}")
        return False
        
    except Exception as e:
        print(f"❌ Erro inesperado: {e}")
        print(f"   Tipo: {type(e)}")
        return False

def check_environment():
    """Verifica o ambiente atual"""
    print("🔍 Verificando ambiente...")
    
    credentials = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if credentials:
        print(f"   GOOGLE_APPLICATION_CREDENTIALS: {credentials}")
        if os.path.exists(credentials):
            print("   ✅ Arquivo de credenciais existe")
        else:
            print("   ❌ Arquivo de credenciais não encontrado")
    else:
        print("   GOOGLE_APPLICATION_CREDENTIALS: NÃO DEFINIDA")
        print("   💡 Usará Application Default Credentials")
    
    project = os.getenv("GOOGLE_CLOUD_PROJECT")
    if project:
        print(f"   GOOGLE_CLOUD_PROJECT: {project}")
    else:
        print("   GOOGLE_CLOUD_PROJECT: NÃO DEFINIDA")

if __name__ == "__main__":
    print("🚀 Teste de Funcionamento da Google Cloud Vision API")
    print("=" * 60)
    
    check_environment()
    print()
    
    if test_vision_api():
        print("\n✅ SUCCESS: Google Cloud Vision API funcionando!")
        exit(0)
    else:
        print("\n❌ FAILED: Problema com Google Cloud Vision API")
        exit(1) 