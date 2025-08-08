import os
import io
import tempfile
from typing import List, Optional
from pathlib import Path

import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pdf2image import convert_from_bytes
from PIL import Image
import aiofiles
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

app = FastAPI(
    title="PDF OCR Vision API (DEMO)",
    description="API DEMO para extração de texto de arquivos PDF - Funcionando sem Google Cloud Vision",
    version="1.0.0-demo"
)

# Configuração CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configurações
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "temp_uploads")

# Criar diretório de upload se não existir
Path(UPLOAD_DIR).mkdir(exist_ok=True)

class TextExtractionResponse(BaseModel):
    """Modelo de resposta para extração de texto"""
    text: str
    confidence: float
    pages: List[dict]
    total_pages: int
    success: bool
    message: str
    is_demo: bool = True

def pdf_to_images(pdf_bytes: bytes) -> List[Image.Image]:
    """Converte PDF em lista de imagens"""
    try:
        images = convert_from_bytes(pdf_bytes, dpi=300)
        return images
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Erro ao converter PDF: {str(e)}")

def extract_text_demo(image: Image.Image, page_number: int) -> dict:
    """Simula extração de texto sem usar Google Cloud Vision"""
    
    # Simular texto extraído baseado no tamanho da imagem
    width, height = image.size
    simulated_texts = [
        f"DOCUMENTO SIMULADO - PÁGINA {page_number}",
        f"Dimensões da imagem: {width}x{height} pixels",
        f"Esta é uma demonstração da API PDF OCR Vision.",
        f"",
        f"CONTEÚDO DE EXEMPLO:",
        f"• Item 1 da página {page_number}",
        f"• Item 2 da página {page_number}",
        f"• Item 3 da página {page_number}",
        f"",
        f"Para usar OCR real, configure:",
        f"1. Google Cloud Vision API",
        f"2. Credenciais de Service Account",
        f"3. Execute: gcloud auth application-default login",
        f"",
        f"Total de pixels processados: {width * height:,}",
        f"Simulação concluída com sucesso!"
    ]
    
    simulated_text = "\n".join(simulated_texts)
    
    return {
        "text": simulated_text,
        "confidence": 0.95,  # Simular alta confiança
        "words_count": len(simulated_text.split())
    }

@app.get("/")
async def root():
    """Endpoint raiz com informações da API"""
    return {
        "message": "PDF OCR Vision API (MODO DEMO)",
        "version": "1.0.0-demo",
        "description": "API DEMO - Funcionando sem Google Cloud Vision para testes",
        "status": "🚧 MODO DEMONSTRAÇÃO 🚧",
        "endpoints": {
            "extract_text": "/extract-text",
            "extract_text_image": "/extract-text-image",
            "health": "/health",
            "docs": "/docs"
        },
        "note": "Esta versão simula extração de texto. Para OCR real, configure Google Cloud Vision."
    }

@app.get("/health")
async def health_check():
    """Endpoint de verificação de saúde"""
    return {
        "status": "healthy",
        "mode": "demo",
        "google_vision": "not_configured",
        "upload_dir": os.path.exists(UPLOAD_DIR),
        "message": "API funcionando em modo demonstração"
    }

@app.post("/extract-text", response_model=TextExtractionResponse)
async def extract_text_from_pdf(
    file: UploadFile = File(..., description="Arquivo PDF para extração de texto"),
    extract_pages: Optional[str] = Form(None, description="Páginas específicas para extrair (ex: '1,3,5' ou 'all')")
):
    """
    DEMO: Simula extração de texto de um arquivo PDF
    
    Args:
        file: Arquivo PDF a ser processado
        extract_pages: Páginas específicas para extrair (opcional, padrão: todas)
    
    Returns:
        TextExtractionResponse com texto simulado
    """
    
    # Validar tipo de arquivo
    if not file.filename.lower().endswith('.pdf'):
        raise HTTPException(
            status_code=400,
            detail="Apenas arquivos PDF são suportados"
        )
    
    try:
        # Ler conteúdo do arquivo
        pdf_content = await file.read()
        
        # Converter PDF para imagens
        images = pdf_to_images(pdf_content)
        total_pages = len(images)
        
        # Determinar quais páginas processar
        pages_to_process = list(range(total_pages))
        if extract_pages and extract_pages.lower() != "all":
            try:
                specified_pages = [int(p.strip()) - 1 for p in extract_pages.split(",")]
                pages_to_process = [p for p in specified_pages if 0 <= p < total_pages]
            except ValueError:
                raise HTTPException(
                    status_code=400,
                    detail="Formato inválido para páginas. Use números separados por vírgula (ex: '1,3,5')"
                )
        
        # Simular extração de texto de cada página
        extracted_pages = []
        all_text = []
        total_confidence = 0
        
        for i, page_num in enumerate(pages_to_process):
            image = images[page_num]
            page_result = extract_text_demo(image, page_num + 1)
            
            page_data = {
                "page_number": page_num + 1,
                "text": page_result["text"],
                "confidence": page_result["confidence"],
                "words_count": page_result["words_count"]
            }
            
            extracted_pages.append(page_data)
            all_text.append(page_result["text"])
            total_confidence += page_result["confidence"]
        
        # Calcular métricas finais
        avg_confidence = total_confidence / len(pages_to_process) if pages_to_process else 0
        combined_text = "\n\n=== NOVA PÁGINA ===\n\n".join(all_text)
        
        return TextExtractionResponse(
            text=combined_text,
            confidence=avg_confidence,
            pages=extracted_pages,
            total_pages=len(pages_to_process),
            success=True,
            message=f"✅ DEMO: Texto simulado para {len(pages_to_process)} página(s). Configure Google Cloud Vision para OCR real.",
            is_demo=True
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno do servidor: {str(e)}"
        )

@app.post("/extract-text-image", response_model=dict)
async def extract_text_from_image_endpoint(
    file: UploadFile = File(..., description="Arquivo de imagem para extração de texto")
):
    """
    DEMO: Simula extração de texto de uma imagem
    
    Args:
        file: Arquivo de imagem a ser processado
    
    Returns:
        Dicionário com texto simulado
    """
    
    # Validar tipo de arquivo
    allowed_types = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff']
    if not any(file.filename.lower().endswith(ext) for ext in allowed_types):
        raise HTTPException(
            status_code=400,
            detail=f"Tipos de arquivo suportados: {', '.join(allowed_types)}"
        )
    
    try:
        # Ler conteúdo do arquivo
        image_content = await file.read()
        
        # Abrir imagem com PIL
        image = Image.open(io.BytesIO(image_content))
        
        # Simular extração
        result = extract_text_demo(image, 1)
        
        return {
            "text": result["text"],
            "confidence": result["confidence"],
            "words_count": result["words_count"],
            "success": True,
            "message": "✅ DEMO: Texto simulado para imagem. Configure Google Cloud Vision para OCR real.",
            "is_demo": True
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno do servidor: {str(e)}"
        )

if __name__ == "__main__":
    # Configurações do servidor
    host = os.getenv("HOST", "0.0.0.0")
    port = 8001  # Porta fixa para demo
    debug = os.getenv("DEBUG", "True").lower() == "true"
    
    print(f"🚧 Iniciando PDF OCR Vision API (MODO DEMO)...")
    print(f"📋 Documentação disponível em: http://localhost:8001/docs")
    print(f"🔍 Health check em: http://localhost:8001/health")
    print(f"⚠️  ATENÇÃO: Esta versão simula extração de texto!")
    print(f"💡 Para OCR real, configure Google Cloud Vision")
    
    uvicorn.run(
        "main_demo:app",
        host=host,
        port=port,
        reload=debug
    ) 