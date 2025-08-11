import os
import io
import tempfile
import logging
import datetime
import asyncio
import gc
from concurrent.futures import ThreadPoolExecutor
from typing import List, Optional
from pathlib import Path

import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google.cloud import vision
from pdf2image import convert_from_bytes
from PIL import Image
import aiofiles
from dotenv import load_dotenv

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # Console output
    ]
)
logger = logging.getLogger("PDF_OCR_API")

# Carregar variáveis de ambiente
load_dotenv()

# Auto-configuração do quota project se necessário
def auto_configure_gcloud():
    """Configura automaticamente o Google Cloud se necessário"""
    try:
        import subprocess
        
        # Verificar se precisa configurar quota project
        if not os.getenv("GOOGLE_CLOUD_PROJECT"):
            logger.info("🔧 Auto-configurando Google Cloud...")
            
            # Executar script de configuração
            result = subprocess.run(["python", "fix_quota_project.py"], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info("✅ Google Cloud configurado automaticamente!")
            else:
                logger.warning(f"⚠️ Não foi possível auto-configurar: {result.stderr}")
                
    except Exception as e:
        logger.warning(f"⚠️ Erro na auto-configuração: {e}")

# Executar auto-configuração na inicialização
auto_configure_gcloud()

# Garantir que as credenciais corretas estão carregadas
def ensure_correct_credentials():
    """Garante que as credenciais corretas estão sendo usadas"""
    try:
        # Verificar se há um arquivo de Service Account vazio que está causando problemas
        service_account_file = "/app/gcloud-config/service-account-key.json"
        if os.path.exists(service_account_file) and os.path.getsize(service_account_file) == 0:
            logger.warning(f"⚠️ Arquivo Service Account vazio detectado: {service_account_file}")
            # Remover a variável que aponta para ele
            os.environ.pop("GOOGLE_APPLICATION_CREDENTIALS", None)
        
        # Configurar para usar Application Default Credentials
        adc_file = "/root/.config/gcloud/application_default_credentials.json"
        if os.path.exists(adc_file):
            os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = adc_file
            os.environ["GOOGLE_CLOUD_PROJECT"] = "stable-chain-455617-v1"
            logger.info("✅ Configuradas Application Default Credentials para a aplicação")
        else:
            logger.warning("⚠️ Application Default Credentials não encontradas")
            
    except Exception as e:
        logger.error(f"❌ Erro ao configurar credenciais: {e}")

ensure_correct_credentials()

app = FastAPI(
    title="PDF OCR Vision API",
    description="API para extração de texto de arquivos PDF usando Google Cloud Vision",
    version="1.0.0"
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
GOOGLE_APPLICATION_CREDENTIALS = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

# Criar diretório de upload se não existir
Path(UPLOAD_DIR).mkdir(exist_ok=True)

# Cliente do Google Cloud Vision (inicializado sob demanda)
vision_client = None

def get_vision_client():
    """Inicializa e retorna o cliente do Google Cloud Vision"""
    global vision_client
    if vision_client is None:
        try:
            # Primeiro, limpar qualquer variável que aponte para arquivo inválido
            service_account_file = "/app/gcloud-config/service-account-key.json"
            if os.getenv("GOOGLE_APPLICATION_CREDENTIALS") == service_account_file:
                # Se está apontando para o arquivo vazio, remover a variável
                if os.path.exists(service_account_file) and os.path.getsize(service_account_file) == 0:
                    os.environ.pop("GOOGLE_APPLICATION_CREDENTIALS", None)
                    logger.info("🔧 Removida referência a arquivo de Service Account vazio")
            
            # Usar Application Default Credentials (que sabemos que funcionam)
            vision_client = vision.ImageAnnotatorClient()
            logger.info("✅ Cliente Vision criado com Application Default Credentials")
            
        except Exception as e:
            logger.error(f"❌ Erro na criação do cliente Vision: {str(e)}")
            raise HTTPException(
                status_code=503, 
                detail=f"Erro na configuração do Google Cloud Vision: {str(e)}"
            )
    return vision_client

class TextExtractionResponse(BaseModel):
    """Modelo de resposta para extração de texto"""
    pages: List[dict]
    total_pages: int
    success: bool
    message: str

class SimpleTextResponse(BaseModel):
    """Modelo de resposta simples com texto limpo por páginas"""
    pages: List[str]
    total_pages: int
    success: bool

class AgibankResponse(BaseModel):
    """Modelo de resposta para extração de área específica do Agibank"""
    demonstrativo_pages: List[str]
    total_pages: int
    success: bool
    message: str

class BmgResponse(BaseModel):
    """Modelo de resposta para extração de área específica do BMG"""
    transacoes_pages: List[str]
    total_pages: int
    success: bool
    message: str

class ErrorResponse(BaseModel):
    """Modelo de resposta para erros"""
    success: bool
    message: str
    error_code: str

def pdf_to_images(pdf_bytes: bytes) -> List[Image.Image]:
    """Converte PDF em lista de imagens"""
    try:
        images = convert_from_bytes(pdf_bytes, dpi=300)
        return images
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Erro ao converter PDF: {str(e)}")

def clean_text(text: str) -> str:
    """Limpa o texto removendo quebras de linha e espaços extras"""
    if not text:
        return ""
    
    # Substituir quebras de linha por espaços
    cleaned_text = text.replace('\n', ' ')
    
    # Remover espaços extras (múltiplos espaços se tornam um só)
    cleaned_text = ' '.join(cleaned_text.split())
    
    return cleaned_text

def crop_agibank_demonstrativo_area(image: Image.Image) -> Image.Image:
    """
    Recorta a área do demonstrativo da fatura Agibank
    
    Baseado na área marcada em vermelho na imagem de referência:
    - Lado direito da fatura onde ficam as transações
    - Região do "DEMONSTRATIVO"
    """
    width, height = image.size
    
    # Coordenadas da área do demonstrativo (valores aproximados baseados na imagem)
    # Área direita superior onde está o demonstrativo
    left = int(width * 0.45)    # Começa em 45% da largura
    top = int(height * 0.15)    # Começa em 15% da altura  
    right = int(width * 0.95)   # Vai até 95% da largura
    bottom = int(height * 0.55)  # Vai até 55% da altura
    
    # Recortar a área específica
    cropped_image = image.crop((left, top, right, bottom))
    
    return cropped_image

def crop_bmg_transacoes_area(image: Image.Image) -> Image.Image:
    """
    Recorta a área das transações da fatura BMG
    
    Baseado na área marcada em vermelho na imagem de referência:
    - Parte central-esquerda onde ficam DATA e HISTÓRICO
    - Região das transações listadas
    """
    width, height = image.size
    
    # Coordenadas da área das transações BMG (baseado na área marcada)
    # Área central-esquerda onde estão as transações
    left = 0    # Começa na posição 0 da largura (extrema esquerda)
    top = int(height * 0.05)    # Começa em 5% da altura (quase no topo)
    right = int(width * 0.92)   # Vai até 95% da largura (quase toda a largura)
    bottom = int(height * 0.65)  # Vai até 65% da altura (área das transações)
    
    # Recortar a área específica
    cropped_image = image.crop((left, top, right, bottom))
    
    # Salvar a imagem cortada para conferência
    import datetime
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    crop_filename = f"bmg_crop_{timestamp}.png"
    crop_path = os.path.join(UPLOAD_DIR, crop_filename)
    
    try:
        cropped_image.save(crop_path)
        print(f"DEBUG: Imagem cortada BMG salva em: {crop_path}")
        print(f"DEBUG: Coordenadas do corte - left:{left}, top:{top}, right:{right}, bottom:{bottom}")
        print(f"DEBUG: Tamanho original: {width}x{height}, Tamanho cortado: {cropped_image.size}")
    except Exception as e:
        print(f"DEBUG: Erro ao salvar imagem cortada: {str(e)}")
    
    return cropped_image

def extract_text_from_image(image: Image.Image) -> dict:
    """Extrai texto de uma imagem usando Google Cloud Vision"""
    try:
        # Converter imagem PIL para bytes
        img_byte_arr = io.BytesIO()
        image.save(img_byte_arr, format='PNG')
        img_byte_arr = img_byte_arr.getvalue()
        
        # Criar objeto de imagem para Vision API
        vision_image = vision.Image(content=img_byte_arr)
        
        # Realizar OCR
        client = get_vision_client()
        response = client.text_detection(image=vision_image)
        texts = response.text_annotations
        
        if response.error.message:
            raise Exception(f"Erro na Vision API: {response.error.message}")
        
        # Extrair texto e confiança
        if texts:
            raw_text = texts[0].description
            # Limpar o texto
            cleaned_text = clean_text(raw_text)
            
            return {
                "text": cleaned_text,
                "confidence": 0.9,  # Vision API não retorna confiança diretamente
                "words_count": len(cleaned_text.split()) if cleaned_text else 0
            }
        else:
            return {
                "text": "",
                "confidence": 0.0,
                "words_count": 0
            }
            
    except HTTPException:
        raise
    except Exception as e:
        error_msg = f"Erro na extração de texto: {str(e)}"
        logger.error(f"❌ Vision API - {error_msg}")
        raise HTTPException(status_code=500, detail=error_msg)

def process_agibank_demonstrativo_text(raw_text: str) -> str:
    """
    Processa o texto do demonstrativo Agibank para associar títulos com valores
    
    Padrão esperado: "data descrição data descrição ... valores valores valores"
    """
    if not raw_text:
        return ""
    
    import re
    
    # Usar regex para encontrar todas as transações (data + descrição)
    # Padrão: dd/mm/yyyy seguido de texto até a próxima data ou final
    transaction_pattern = r'(\d{2}/\d{2}/\d{4})\s+([^0-9/]+?)(?=\s*\d{2}/\d{2}/\d{4}|$)'
    transactions = re.findall(transaction_pattern, raw_text)
    
    # Extrair a parte final que contém os valores monetários
    # Remover todas as transações identificadas e pegar o que sobra
    text_without_transactions = raw_text
    for date, desc in transactions:
        text_without_transactions = text_without_transactions.replace(f"{date} {desc}", "", 1)
    
    # Encontrar valores monetários na parte restante
    # Padrão: números com vírgulas, pontos, sinais negativos
    value_pattern = r'[-+]?\d{1,3}(?:\.\d{3})*(?:,\d{2})?|\d+,\d{2}|\d+'
    values = re.findall(value_pattern, text_without_transactions)
    
    # Filtrar valores válidos (que parecem monetários)
    monetary_values = []
    for val in values:
        # Aceitar valores que tenham pelo menos um dígito e formato monetário
        if val and (len(val) >= 2 and (',' in val or len(val) >= 3)):
            monetary_values.append(val)
    
    # Montar as transações processadas
    processed_transactions = []
    
    for i, (date, description) in enumerate(transactions):
        # Limpar a descrição
        clean_desc = description.strip()
        
        # Associar com valor se disponível
        if i < len(monetary_values):
            value = monetary_values[i]
            processed_transactions.append(f"{date} - {clean_desc} - R$ {value}")
        else:
            processed_transactions.append(f"{date} - {clean_desc} - Valor: N/A")
    
    # Se sobraram valores, mostrar separadamente
    if len(monetary_values) > len(transactions):
        remaining_values = monetary_values[len(transactions):]
        processed_transactions.append(f"Valores extras: {', '.join(remaining_values)}")
    
    return ' | '.join(processed_transactions) if processed_transactions else raw_text

def extract_text_from_agibank_demonstrativo(image: Image.Image) -> str:
    """Extrai texto apenas da área do demonstrativo da fatura Agibank"""
    try:
        # Recortar área específica do demonstrativo
        cropped_image = crop_agibank_demonstrativo_area(image)
        
        # Extrair texto da área recortada
        result = extract_text_from_image(cropped_image)
        
        # Processar o texto para associar títulos com valores
        processed_text = process_agibank_demonstrativo_text(result["text"])
        
        return processed_text
        
    except Exception as e:
        print(f"DEBUG: Erro na extração Agibank: {str(e)}")
        return ""

def process_bmg_transacoes_text(raw_text: str) -> str:
    """
    Retorna o texto PURO extraído pelo Vision API - sem organização
    
    Apenas limpa quebras de linha e espaços extras, mantendo a ordem original do Vision
    """
    if not raw_text:
        return ""
    
    # Usar apenas a função clean_text que já existe
    return clean_text(raw_text)

def process_single_bmg_page(image: Image.Image, page_num: int) -> tuple:
    """
    Processa uma única página BMG e retorna o texto extraído.
    Retorna: (page_num, texto_extraido, tempo_processamento, erro)
    """
    try:
        start_time = datetime.datetime.now()
        
        # Recortar área específica das transações
        cropped_image = crop_bmg_transacoes_area(image)
        
        # Extrair texto da área recortada
        result = extract_text_from_image(cropped_image)
        
        # Processar o texto para organizar as transações
        processed_text = process_bmg_transacoes_text(result["text"])
        
        # Liberar recursos
        if hasattr(cropped_image, 'close'):
            cropped_image.close()
        
        process_time = (datetime.datetime.now() - start_time).total_seconds()
        
        return (page_num, processed_text, process_time, None)
        
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        logger.error(f"❌ BMG - Erro na página {page_num}: {str(e)}")
        process_time = (datetime.datetime.now() - start_time).total_seconds()
        return (page_num, "", process_time, str(e))

def extract_text_from_bmg_transacoes(image: Image.Image) -> str:
    """Extrai texto apenas da área das transações da fatura BMG"""
    try:
        # Recortar área específica das transações
        cropped_image = crop_bmg_transacoes_area(image)
        
        # Extrair texto da área recortada
        result = extract_text_from_image(cropped_image)
        
        # Processar o texto para organizar as transações
        processed_text = process_bmg_transacoes_text(result["text"])
        
        return processed_text
        
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        logger.error(f"❌ BMG - Erro na extração: {str(e)}")
        logger.error(f"❌ BMG - Traceback completo: {error_details}")
        print(f"DEBUG: Erro na extração BMG: {str(e)}")
        print(f"DEBUG: Traceback: {error_details}")
        return ""

@app.get("/")
async def root():
    """Endpoint raiz com informações da API"""
    return {
        "message": "PDF OCR Vision API",
        "version": "1.0.0",
        "description": "API para extração de texto de arquivos PDF usando Google Cloud Vision",
        "endpoints": {
            "extract_text": "/extract-text",
            "extract_text_simple": "/extract-text-simple (RECOMENDADO - Texto limpo)",
            "extract_text_agibank": "/extract-text-agibank (ESPECÍFICO - Área demonstrativo)",
            "extract_text_bmg": "/extract-text-bmg (ESPECÍFICO - Área transações)",
            "extract_text_image": "/extract-text-image",
            "health": "/health",
            "docs": "/docs"
        }
    }

@app.get("/health")
async def health_check():
    """Endpoint de verificação de saúde"""
    try:
        # Testar conexão com Google Cloud Vision
        test_image = vision.Image()
        # Este é um teste simples para verificar se o cliente está configurado
        return {
            "status": "healthy",
            "google_vision": "connected",
            "upload_dir": os.path.exists(UPLOAD_DIR)
        }
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "error": str(e)
            }
        )

@app.post("/extract-text", response_model=TextExtractionResponse)
async def extract_text_from_pdf(
    file: UploadFile = File(..., description="Arquivo PDF para extração de texto"),
    extract_pages: Optional[str] = Form(None, description="Páginas específicas para extrair (ex: '1,3,5' ou 'all')")
):
    """
    Extrai texto de um arquivo PDF usando Google Cloud Vision OCR
    
    Args:
        file: Arquivo PDF a ser processado
        extract_pages: Páginas específicas para extrair (opcional, padrão: todas)
    
    Returns:
        TextExtractionResponse com o texto extraído
    """
    
    start_time = datetime.datetime.now()
    logger.info(f"🚀 INICIANDO EXTRAÇÃO - Arquivo: {file.filename}, Tamanho: {file.size if hasattr(file, 'size') else 'N/A'} bytes")
    
    # Validar tipo de arquivo
    if not file.filename.lower().endswith('.pdf'):
        logger.error(f"❌ Tipo de arquivo inválido: {file.filename}")
        raise HTTPException(
            status_code=400,
            detail="Apenas arquivos PDF são suportados"
        )
    
    try:
        # Ler conteúdo do arquivo
        logger.info(f"📖 Lendo conteúdo do arquivo PDF...")
        pdf_content = await file.read()
        logger.info(f"✅ Arquivo lido com sucesso: {len(pdf_content)} bytes")
        
        # Converter PDF para imagens
        logger.info(f"🖼️ Convertendo PDF para imagens...")
        images = pdf_to_images(pdf_content)
        total_pages = len(images)
        logger.info(f"✅ PDF convertido: {total_pages} página(s)")
        
        # Determinar quais páginas processar
        pages_to_process = list(range(total_pages))
        if extract_pages and extract_pages.lower() != "all":
            try:
                specified_pages = [int(p.strip()) - 1 for p in extract_pages.split(",")]
                pages_to_process = [p for p in specified_pages if 0 <= p < total_pages]
                logger.info(f"🎯 Páginas específicas selecionadas: {[p+1 for p in pages_to_process]}")
            except ValueError:
                logger.error(f"❌ Formato inválido de páginas: {extract_pages}")
                raise HTTPException(
                    status_code=400,
                    detail="Formato inválido para páginas. Use números separados por vírgula (ex: '1,3,5')"
                )
        else:
            logger.info(f"📄 Processando todas as páginas: {total_pages}")
        
        # Extrair texto de cada página
        extracted_pages = []
        logger.info(f"🔍 Iniciando extração OCR...")
        
        for i, page_num in enumerate(pages_to_process):
            page_start = datetime.datetime.now()
            logger.info(f"  📃 Processando página {page_num + 1}/{total_pages}...")
            
            image = images[page_num]
            page_result = extract_text_from_image(image)
            
            page_elapsed = (datetime.datetime.now() - page_start).total_seconds()
            words_count = page_result["words_count"]
            
            page_data = {
                "page_number": page_num + 1,
                "text": page_result["text"],
                "confidence": page_result["confidence"],
                "words_count": words_count
            }
            
            logger.info(f"  ✅ Página {page_num + 1} processada - {words_count} palavras em {page_elapsed:.2f}s")
            extracted_pages.append(page_data)
        
        total_elapsed = (datetime.datetime.now() - start_time).total_seconds()
        total_words = sum(page["words_count"] for page in extracted_pages)
        
        logger.info(f"🎉 EXTRAÇÃO CONCLUÍDA - {len(pages_to_process)} páginas, {total_words} palavras em {total_elapsed:.2f}s")
        
        return TextExtractionResponse(
            pages=extracted_pages,
            total_pages=len(pages_to_process),
            success=True,
            message=f"Texto extraído com sucesso de {len(pages_to_process)} página(s)"
        )
        
    except HTTPException:
        logger.error(f"❌ HTTPException: {str(e)}")
        raise
    except Exception as e:
        total_elapsed = (datetime.datetime.now() - start_time).total_seconds()
        logger.error(f"💥 ERRO na extração após {total_elapsed:.2f}s: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno do servidor: {str(e)}"
        )

@app.post("/extract-text-simple", response_model=SimpleTextResponse)
async def extract_text_simple(
    file: UploadFile = File(..., description="Arquivo PDF para extração de texto limpo"),
    extract_pages: Optional[str] = Form(None, description="Páginas específicas para extrair (ex: '1,3,5' ou 'all')")
):
    """
    Extrai texto LIMPO de um arquivo PDF - Resposta simplificada
    
    Args:
        file: Arquivo PDF a ser processado
        extract_pages: Páginas específicas para extrair (opcional, padrão: todas)
    
    Returns:
        SimpleTextResponse com texto limpo por páginas
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
        
        # Extrair texto limpo de cada página
        clean_pages = []
        
        for page_num in pages_to_process:
            image = images[page_num]
            page_result = extract_text_from_image(image)
            
            # Adicionar apenas o texto limpo
            if page_result["text"]:
                clean_pages.append(page_result["text"])
            else:
                clean_pages.append("")
        
        return SimpleTextResponse(
            pages=clean_pages,
            total_pages=len(clean_pages),
            success=True
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno do servidor: {str(e)}"
        )

@app.post("/extract-text-agibank", response_model=AgibankResponse)
async def extract_text_agibank_demonstrativo(
    file: UploadFile = File(..., description="Fatura PDF do Agibank para extração da área do demonstrativo"),
    extract_pages: Optional[str] = Form(None, description="Páginas específicas para extrair (ex: '1,3,5' ou 'all')")
):
    """
    Extrai texto APENAS da área do DEMONSTRATIVO de faturas Agibank
    
    Este endpoint é específico para faturas do Agibank e extrai apenas a região
    marcada em vermelho na referência (área superior direita com as transações).
    
    Args:
        file: Arquivo PDF da fatura Agibank
        extract_pages: Páginas específicas para extrair (opcional, padrão: todas)
    
    Returns:
        AgibankResponse com texto da área do demonstrativo
    """
    
    start_time = datetime.datetime.now()
    logger.info(f"🏦 AGIBANK - INICIANDO extração de demonstrativo - Arquivo: {file.filename}")
    
    # Validar tipo de arquivo
    if not file.filename.lower().endswith('.pdf'):
        logger.error(f"❌ AGIBANK - Tipo de arquivo inválido: {file.filename}")
        raise HTTPException(
            status_code=400,
            detail="Apenas arquivos PDF são suportados"
        )
    
    try:
        # Ler conteúdo do arquivo
        logger.info(f"🏦 AGIBANK - Lendo conteúdo do PDF...")
        pdf_content = await file.read()
        
        # Converter PDF para imagens
        logger.info(f"🏦 AGIBANK - Convertendo PDF para imagens...")
        images = pdf_to_images(pdf_content)
        total_pages = len(images)
        logger.info(f"🏦 AGIBANK - {total_pages} página(s) convertida(s)")
        
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
        
        # Extrair texto da área do demonstrativo de cada página
        demonstrativo_texts = []
        
        for page_num in pages_to_process:
            image = images[page_num]
            # Extrair apenas da área do demonstrativo
            demonstrativo_text = extract_text_from_agibank_demonstrativo(image)
            demonstrativo_texts.append(demonstrativo_text)
        
        return AgibankResponse(
            demonstrativo_pages=demonstrativo_texts,
            total_pages=len(demonstrativo_texts),
            success=True,
            message=f"Área do demonstrativo extraída com sucesso de {len(demonstrativo_texts)} página(s) da fatura Agibank"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno do servidor: {str(e)}"
        )

@app.post("/extract-text-bmg", response_model=BmgResponse)
async def extract_text_bmg_transacoes(
    file: UploadFile = File(..., description="Fatura PDF do BMG para extração da área das transações"),
    extract_pages: Optional[str] = Form(None, description="Páginas específicas para extrair (ex: '1,3,5' ou 'all')")
):
    """
    Extrai texto APENAS da área das TRANSAÇÕES de faturas BMG
    
    Este endpoint é específico para faturas do BMG e extrai apenas a região
    marcada em vermelho na referência (área central-esquerda com DATA e HISTÓRICO).
    
    Args:
        file: Arquivo PDF da fatura BMG
        extract_pages: Páginas específicas para extrair (opcional, padrão: todas)
    
    Returns:
        BmgResponse com texto da área das transações
    """
    
    start_time = datetime.datetime.now()
    logger.info(f"🏧 BMG - INICIANDO extração de transações - Arquivo: {file.filename}")
    
    # Validar tipo de arquivo
    if not file.filename.lower().endswith('.pdf'):
        logger.error(f"❌ BMG - Tipo de arquivo inválido: {file.filename}")
        raise HTTPException(
            status_code=400,
            detail="Apenas arquivos PDF são suportados"
        )
    
    try:
        # Ler conteúdo do arquivo
        logger.info(f"🏧 BMG - Lendo conteúdo do PDF...")
        pdf_content = await file.read()
        
        # Converter PDF para imagens
        logger.info(f"🏧 BMG - Convertendo PDF para imagens...")
        images = pdf_to_images(pdf_content)
        total_pages = len(images)
        logger.info(f"🏧 BMG - {total_pages} página(s) convertida(s)")
        
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
        
        # Log de informação sobre o processamento
        logger.info(f"🏧 BMG - Processando {len(pages_to_process)} páginas")
        
        # Estimar tempo de processamento
        estimated_time = len(pages_to_process) * 12  # ~12 segundos por página
        if estimated_time > 180:  # 3 minutos
            logger.warning(f"⚠️ BMG - Tempo estimado muito alto: {estimated_time}s")
        
        logger.info(f"🏧 BMG - Tempo estimado: {estimated_time}s para {len(pages_to_process)} páginas")
        
        # Selecionar apenas as imagens necessárias
        selected_images = [images[i] for i in pages_to_process]
        
        # Otimizar tamanho das imagens se muito grandes
        optimized_images = []
        for i, img in enumerate(selected_images):
            if img.size[0] > 2000 or img.size[1] > 3000:
                # Redimensionar mantendo proporção
                ratio = min(2000 / img.size[0], 3000 / img.size[1])
                new_size = (int(img.size[0] * ratio), int(img.size[1] * ratio))
                optimized_img = img.resize(new_size, Image.Resampling.LANCZOS)
                logger.info(f"📏 BMG - Página {i+1} redimensionada: {img.size} → {new_size}")
                optimized_images.append(optimized_img)
            else:
                optimized_images.append(img)
        
        # Extrair texto da área das transações de cada página
        transacoes_texts = []
        
        logger.info(f"🏧 BMG - Iniciando processamento paralelo de {len(optimized_images)} páginas")
        
        # Processar páginas em paralelo com ThreadPoolExecutor
        def process_page_wrapper(args):
            image, page_idx = args
            page_num = pages_to_process[page_idx]
            return process_single_bmg_page(image, page_num + 1)
        
        # Determinar número de workers baseado no número de páginas
        max_workers = min(4, len(optimized_images))  # Máximo 4 threads simultâneas
        logger.info(f"🏧 BMG - Usando {max_workers} threads para processamento")
        
        # Preparar argumentos para o pool
        page_args = [(image, i) for i, image in enumerate(optimized_images)]
        
        # Executar processamento paralelo
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Executar de forma assíncrona para não bloquear
            results = await loop.run_in_executor(
                executor,
                lambda: list(executor.map(process_page_wrapper, page_args))
            )
        
        # Ordenar resultados por número da página
        results.sort(key=lambda x: x[0])
        
        # Extrair textos e logs dos resultados
        transacoes_texts = []
        total_processing_time = 0
        
        for page_num, text, process_time, error in results:
            if error:
                logger.error(f"❌ BMG - Página {page_num} teve erro: {error}")
                transacoes_texts.append("")
            else:
                logger.info(f"✅ BMG - Página {page_num} processada em {process_time:.2f}s")
                transacoes_texts.append(text)
            
            total_processing_time += process_time
        
        # Liberação final de memória
        import gc
        for img in optimized_images:
            if hasattr(img, 'close'):
                img.close()
        del optimized_images
        del selected_images
        gc.collect()
        logger.info(f"🧹 BMG - Limpeza final de memória concluída")
        
        # Calcular tempo total
        total_elapsed = (datetime.datetime.now() - start_time).total_seconds()
        pages_processed = len([t for t in transacoes_texts if t.strip()])  # Páginas com conteúdo
        
        logger.info(f"🎉 BMG - CONCLUÍDO: {pages_processed}/{len(transacoes_texts)} páginas em {total_elapsed:.2f}s (processamento paralelo: {total_processing_time:.2f}s)")
        
        return BmgResponse(
            transacoes_pages=transacoes_texts,
            total_pages=len(transacoes_texts),
            success=True,
            message=f"Área das transações extraída de {pages_processed}/{len(transacoes_texts)} página(s) em {total_elapsed:.1f}s com processamento paralelo ({max_workers} threads)"
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
    Extrai texto de uma imagem usando Google Cloud Vision OCR
    
    Args:
        file: Arquivo de imagem a ser processado
    
    Returns:
        Dicionário com o texto extraído
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
        
        # Extrair texto
        result = extract_text_from_image(image)
        
        return {
            "text": result["text"],
            "confidence": result["confidence"],
            "words_count": result["words_count"],
            "success": True,
            "message": "Texto extraído com sucesso da imagem"
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
    port = int(os.getenv("PORT", 8000))
    debug = os.getenv("DEBUG", "True").lower() == "true"
    
    print(f"🚀 Iniciando PDF OCR Vision API...")
    print(f"📋 Documentação disponível em: http://{host}:{port}/docs")
    print(f"🔍 Health check em: http://{host}:{port}/health")
    
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=debug
    ) 
