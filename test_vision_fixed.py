#!/usr/bin/env python3
"""
Teste corrigido da Google Cloud Vision API com imagem válida
"""

import os
import base64
from google.cloud import vision
from google.auth.exceptions import DefaultCredentialsError

def test_vision_with_valid_image():
    """Testa a Vision API com uma imagem PNG válida"""
    print("🧪 Testando Google Cloud Vision API...")
    
    try:
        # Criar cliente
        client = vision.ImageAnnotatorClient()
        print("✅ Cliente criado com sucesso!")
        
        # Criar uma imagem PNG 1x1 válida (pixel preto)
        # Esta é uma imagem PNG real e mínima
        png_data = base64.b64decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAFFeaR3kwAAAABJRU5ErkJggg=='
        )
        
        # Configurar a imagem
        image = vision.Image(content=png_data)
        
        # Testar detecção de texto
        response = client.text_detection(image=image)
        
        # Verificar se há erro na resposta
        if response.error.message:
            print(f"❌ Erro da API: {response.error.message}")
            return False
        
        print("✅ API Vision respondeu com sucesso!")
        
        # Verificar anotações de texto
        texts = response.text_annotations
        print(f"📄 Texto detectado: {len(texts)} anotação(s)")
        
        if texts:
            print(f"   Texto encontrado: '{texts[0].description.strip()}'")
        else:
            print("   Nenhum texto encontrado (normal para imagem 1x1)")
        
        print("✅ Google Cloud Vision API funcionando perfeitamente!")
        return True
        
    except DefaultCredentialsError as e:
        print(f"❌ Erro de credenciais: {e}")
        return False
        
    except Exception as e:
        print(f"❌ Erro inesperado: {e}")
        print(f"   Tipo: {type(e)}")
        return False

def test_vision_with_features():
    """Testa a Vision API especificando features explicitamente"""
    print("\n🔍 Testando com features específicas...")
    
    try:
        client = vision.ImageAnnotatorClient()
        
        # Imagem PNG 1x1 válida
        png_data = base64.b64decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAFFeaR3kwAAAABJRU5ErkJggg=='
        )
        
        image = vision.Image(content=png_data)
        
        # Especificar features explicitamente
        features = [vision.Feature(type_=vision.Feature.Type.TEXT_DETECTION)]
        
        # Fazer request com features
        request = vision.AnnotateImageRequest(image=image, features=features)
        response = client.annotate_image(request=request)
        
        if response.error.message:
            print(f"❌ Erro com features: {response.error.message}")
            return False
            
        print("✅ Teste com features específicas funcionou!")
        return True
        
    except Exception as e:
        print(f"❌ Erro no teste com features: {e}")
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
    print("🚀 Teste CORRIGIDO da Google Cloud Vision API")
    print("=" * 60)
    
    check_environment()
    print()
    
    # Configurar variáveis se necessário
    if not os.getenv("GOOGLE_CLOUD_PROJECT"):
        os.environ["GOOGLE_CLOUD_PROJECT"] = "stable-chain-455617-v1"
    
    success1 = test_vision_with_valid_image()
    success2 = test_vision_with_features()
    
    if success1 or success2:
        print("\n🎉 SUCESSO: Google Cloud Vision API funcionando!")
        print("=" * 60)
        print("✅ Autenticação OK")
        print("✅ Credenciais válidas") 
        print("✅ API Vision acessível")
        print("✅ Pronto para usar na aplicação!")
        print("\n🚀 Agora você pode executar: python main.py")
        exit(0)
    else:
        print("\n❌ FALHA: Ainda há problemas com a API")
        exit(1) 