#!/usr/bin/env python3
"""
Script de debug específico para o problema da extração BMG
"""

import os
import io
import traceback
from pathlib import Path
from PIL import Image
from google.cloud import vision
from google.auth.exceptions import DefaultCredentialsError

# Configurar variáveis de ambiente
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/root/.config/gcloud/application_default_credentials.json'
os.environ['GOOGLE_CLOUD_PROJECT'] = 'stable-chain-455617-v1'

def test_vision_client_creation():
    """Testa se consegue criar o cliente Vision"""
    print("🔧 Testando criação do cliente Vision...")
    try:
        client = vision.ImageAnnotatorClient()
        print("✅ Cliente Vision criado com sucesso!")
        return client
    except Exception as e:
        print(f"❌ Erro ao criar cliente Vision: {e}")
        print(f"   Tipo: {type(e)}")
        return None

def test_image_processing():
    """Testa o processamento de imagem"""
    print("\n🖼️ Testando processamento de imagem...")
    try:
        # Criar uma imagem teste simples
        test_image = Image.new('RGB', (100, 100), color='white')
        print("✅ Imagem teste criada")
        
        # Converter para bytes
        img_byte_arr = io.BytesIO()
        test_image.save(img_byte_arr, format='PNG')
        img_bytes = img_byte_arr.getvalue()
        print("✅ Conversão para bytes funcionou")
        
        return test_image, img_bytes
    except Exception as e:
        print(f"❌ Erro no processamento de imagem: {e}")
        return None, None

def test_vision_api_call(client, img_bytes):
    """Testa a chamada da Vision API"""
    print("\n📡 Testando chamada da Vision API...")
    try:
        # Criar objeto de imagem para Vision API
        vision_image = vision.Image(content=img_bytes)
        print("✅ Objeto vision.Image criado")
        
        # Fazer chamada para text_detection
        response = client.text_detection(image=vision_image)
        print("✅ Chamada text_detection realizada")
        
        # Verificar se há erro na resposta
        if response.error.message:
            print(f"❌ Erro na resposta da Vision API: {response.error.message}")
            return False
        
        print("✅ Vision API respondeu sem erros")
        return True
        
    except Exception as e:
        print(f"❌ Erro na chamada da Vision API: {e}")
        print(f"   Tipo: {type(e)}")
        print(f"   Traceback completo:")
        traceback.print_exc()
        return False

def test_bmg_crop_function():
    """Testa a função de corte BMG"""
    print("\n✂️ Testando função de corte BMG...")
    try:
        # Criar uma imagem de teste grande o suficiente
        test_image = Image.new('RGB', (2480, 3509), color='white')
        print("✅ Imagem teste BMG criada (2480x3509)")
        
        # Simular o corte BMG
        left, top, right, bottom = 0, 175, 2281, 2280
        cropped = test_image.crop((left, top, right, bottom))
        print(f"✅ Corte realizado: {cropped.size}")
        
        return cropped
        
    except Exception as e:
        print(f"❌ Erro na função de corte: {e}")
        print(f"   Traceback completo:")
        traceback.print_exc()
        return None

def debug_bmg_extraction():
    """Debug completo da extração BMG"""
    print("🔍 DEBUG COMPLETO DA EXTRAÇÃO BMG")
    print("=" * 50)
    
    # Teste 1: Cliente Vision
    client = test_vision_client_creation()
    if not client:
        return False
    
    # Teste 2: Processamento de imagem
    test_image, img_bytes = test_image_processing()
    if not test_image or not img_bytes:
        return False
    
    # Teste 3: Vision API Call
    if not test_vision_api_call(client, img_bytes):
        return False
    
    # Teste 4: Função de corte BMG
    cropped_image = test_bmg_crop_function()
    if not cropped_image:
        return False
    
    # Teste 5: Vision API com imagem cortada
    print("\n🧪 Testando Vision API com imagem cortada...")
    try:
        img_byte_arr = io.BytesIO()
        cropped_image.save(img_byte_arr, format='PNG')
        cropped_bytes = img_byte_arr.getvalue()
        
        if test_vision_api_call(client, cropped_bytes):
            print("✅ Vision API funciona com imagem cortada!")
        else:
            print("❌ Problema com Vision API na imagem cortada")
            return False
            
    except Exception as e:
        print(f"❌ Erro no teste com imagem cortada: {e}")
        traceback.print_exc()
        return False
    
    print("\n🎉 TODOS OS TESTES PASSARAM!")
    print("   O problema pode estar em:")
    print("   1. Arquivo PDF específico")
    print("   2. Conversão PDF → Imagem")
    print("   3. Tamanho da imagem sendo muito grande")
    print("   4. Formato da imagem")
    
    return True

def check_temp_files():
    """Verifica arquivos temporários"""
    print("\n📁 Verificando arquivos temporários...")
    temp_dir = Path("temp_uploads")
    if temp_dir.exists():
        files = list(temp_dir.glob("bmg_crop_*.png"))
        print(f"   Encontrados {len(files)} arquivos de corte BMG")
        for f in files[-3:]:  # Últimos 3 arquivos
            print(f"   - {f.name}: {f.stat().st_size} bytes")
    else:
        print("   Diretório temp_uploads não encontrado")

if __name__ == "__main__":
    print("🚀 SCRIPT DE DEBUG - EXTRAÇÃO BMG")
    print("=" * 60)
    
    check_temp_files()
    
    if debug_bmg_extraction():
        print("\n✅ DEBUG CONCLUÍDO - Problema não é básico")
        print("💡 Execute este script após reproduzir o erro para mais detalhes")
    else:
        print("\n❌ DEBUG FALHOU - Problema identificado")
        print("💡 Verifique os erros acima para resolver") 