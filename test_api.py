"""
Script de exemplo para testar a API PDF OCR Vision

Execute este script depois de iniciar a API para testar os endpoints
"""

import requests
import json
from pathlib import Path

# Configurações
API_BASE_URL = "http://localhost:8000"

def test_health_check():
    """Testa o endpoint de health check"""
    print("🔍 Testando health check...")
    
    try:
        response = requests.get(f"{API_BASE_URL}/health")
        print(f"Status: {response.status_code}")
        print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_api_info():
    """Testa o endpoint de informações da API"""
    print("\n📋 Testando informações da API...")
    
    try:
        response = requests.get(f"{API_BASE_URL}/")
        print(f"Status: {response.status_code}")
        print(f"Resposta: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_pdf_extraction(pdf_path: str, pages: str = None):
    """
    Testa o endpoint de extração de texto de PDF
    
    Args:
        pdf_path: Caminho para o arquivo PDF
        pages: Páginas para extrair (opcional)
    """
    print(f"\n📄 Testando extração de PDF: {pdf_path}")
    
    if not Path(pdf_path).exists():
        print(f"❌ Arquivo não encontrado: {pdf_path}")
        return False
    
    try:
        # Preparar arquivos e dados
        files = {"file": open(pdf_path, "rb")}
        data = {}
        
        if pages:
            data["extract_pages"] = pages
        
        response = requests.post(
            f"{API_BASE_URL}/extract-text",
            files=files,
            data=data
        )
        
        files["file"].close()
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Sucesso!")
            print(f"Páginas processadas: {result.get('total_pages', 0)}")
            print(f"Confiança média: {result.get('confidence', 0):.2f}")
            print(f"Texto extraído (primeiros 200 caracteres): {result.get('text', '')[:200]}...")
        else:
            print(f"❌ Erro: {response.text}")
        
        return response.status_code == 200
        
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_image_extraction(image_path: str):
    """
    Testa o endpoint de extração de texto de imagem
    
    Args:
        image_path: Caminho para o arquivo de imagem
    """
    print(f"\n🖼️ Testando extração de imagem: {image_path}")
    
    if not Path(image_path).exists():
        print(f"❌ Arquivo não encontrado: {image_path}")
        return False
    
    try:
        files = {"file": open(image_path, "rb")}
        
        response = requests.post(
            f"{API_BASE_URL}/extract-text-image",
            files=files
        )
        
        files["file"].close()
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Sucesso!")
            print(f"Palavras encontradas: {result.get('words_count', 0)}")
            print(f"Confiança: {result.get('confidence', 0):.2f}")
            print(f"Texto extraído: {result.get('text', '')[:200]}...")
        else:
            print(f"❌ Erro: {response.text}")
        
        return response.status_code == 200
        
    except Exception as e:
        print(f"Erro: {e}")
        return False

def main():
    """Função principal para executar todos os testes"""
    print("🚀 Iniciando testes da PDF OCR Vision API")
    print("=" * 50)
    
    # Teste básico da API
    if not test_api_info():
        print("❌ API não está funcionando corretamente")
        return
    
    # Teste de health check
    if not test_health_check():
        print("⚠️  Health check falhou - verifique as configurações do Google Cloud")
    
    print("\n" + "=" * 50)
    print("🧪 Para testar extração de arquivos:")
    print("1. Coloque um arquivo PDF de teste na pasta do projeto")
    print("2. Execute:")
    print("   python test_api.py --pdf caminho/para/arquivo.pdf")
    print("   python test_api.py --image caminho/para/imagem.jpg")
    
    print("\nExemplos de uso:")
    print('test_pdf_extraction("documento.pdf")')
    print('test_pdf_extraction("documento.pdf", pages="1,2,3")')
    print('test_image_extraction("imagem.jpg")')

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 2:
        if sys.argv[1] == "--pdf":
            pdf_path = sys.argv[2]
            pages = sys.argv[3] if len(sys.argv) > 3 else None
            test_pdf_extraction(pdf_path, pages)
        elif sys.argv[1] == "--image":
            image_path = sys.argv[2]
            test_image_extraction(image_path)
        else:
            print("Uso: python test_api.py [--pdf arquivo.pdf] [--image imagem.jpg]")
    else:
        main() 