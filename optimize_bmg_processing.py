#!/usr/bin/env python3
"""
Otimizações para processamento de múltiplas páginas BMG
"""

import asyncio
import gc
import logging
from typing import List
from PIL import Image
from concurrent.futures import ThreadPoolExecutor, as_completed
import time

logger = logging.getLogger("PDF_OCR_API")

def process_bmg_page_batch(images: List[Image.Image], batch_size: int = 2) -> List[str]:
    """
    Processa páginas BMG em batches para evitar sobrecarga de memória
    
    Args:
        images: Lista de imagens PIL para processar
        batch_size: Número de páginas a processar por vez
    
    Returns:
        Lista com textos extraídos de cada página
    """
    from main import extract_text_from_bmg_transacoes  # Import local para evitar circular
    
    results = []
    total_pages = len(images)
    
    logger.info(f"🏧 BMG - Processando {total_pages} páginas em batches de {batch_size}")
    
    for i in range(0, total_pages, batch_size):
        batch_start = time.time()
        batch_end = min(i + batch_size, total_pages)
        batch_images = images[i:batch_end]
        
        logger.info(f"🏧 BMG - Processando batch {i//batch_size + 1}: páginas {i+1}-{batch_end}")
        
        # Processar batch atual
        batch_results = []
        for j, image in enumerate(batch_images):
            page_num = i + j + 1
            page_start = time.time()
            
            try:
                text = extract_text_from_bmg_transacoes(image)
                batch_results.append(text)
                
                page_time = time.time() - page_start
                logger.info(f"  ✅ Página {page_num} processada em {page_time:.2f}s")
                
            except Exception as e:
                logger.error(f"  ❌ Erro na página {page_num}: {str(e)}")
                batch_results.append("")  # Adicionar string vazia em caso de erro
        
        results.extend(batch_results)
        
        # Liberar memória após cada batch
        for img in batch_images:
            if hasattr(img, 'close'):
                img.close()
        del batch_images
        gc.collect()
        
        batch_time = time.time() - batch_start
        logger.info(f"  🏁 Batch concluído em {batch_time:.2f}s - Memória liberada")
        
        # Pequena pausa entre batches para estabilizar
        if batch_end < total_pages:
            time.sleep(0.1)
    
    return results

async def process_bmg_pages_async(images: List[Image.Image], max_workers: int = 2) -> List[str]:
    """
    Processa páginas BMG de forma assíncrona com controle de concorrência
    
    Args:
        images: Lista de imagens PIL para processar
        max_workers: Número máximo de workers simultâneos
    
    Returns:
        Lista com textos extraídos de cada página
    """
    from main import extract_text_from_bmg_transacoes
    
    logger.info(f"🏧 BMG - Processamento assíncrono com {max_workers} workers")
    
    def process_single_page(page_data):
        page_num, image = page_data
        try:
            start_time = time.time()
            text = extract_text_from_bmg_transacoes(image)
            end_time = time.time()
            
            logger.info(f"  ✅ Página {page_num + 1} processada em {end_time - start_time:.2f}s")
            return page_num, text
            
        except Exception as e:
            logger.error(f"  ❌ Erro na página {page_num + 1}: {str(e)}")
            return page_num, ""
        finally:
            # Liberar imagem após processamento
            if hasattr(image, 'close'):
                image.close()
    
    # Executar processamento em thread pool
    loop = asyncio.get_event_loop()
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Preparar dados para processamento
        page_data = [(i, img) for i, img in enumerate(images)]
        
        # Submeter todas as tarefas
        future_to_page = {
            loop.run_in_executor(executor, process_single_page, data): data[0]
            for data in page_data
        }
        
        # Coletar resultados conforme ficam prontos
        results = [""] * len(images)  # Inicializar lista com strings vazias
        
        for future in as_completed(future_to_page):
            try:
                page_num, text = await future
                results[page_num] = text
            except Exception as e:
                page_num = future_to_page[future]
                logger.error(f"❌ Erro crítico na página {page_num + 1}: {str(e)}")
                results[page_num] = ""
    
    # Liberação final de memória
    gc.collect()
    
    return results

def optimize_images_for_processing(images: List[Image.Image], max_size: tuple = (2000, 3000)) -> List[Image.Image]:
    """
    Otimiza imagens para processamento reduzindo tamanho se necessário
    
    Args:
        images: Lista de imagens PIL
        max_size: Tamanho máximo (largura, altura)
    
    Returns:
        Lista de imagens otimizadas
    """
    optimized = []
    
    for i, img in enumerate(images):
        # Verificar se precisa redimensionar
        if img.size[0] > max_size[0] or img.size[1] > max_size[1]:
            # Calcular novo tamanho mantendo proporção
            ratio = min(max_size[0] / img.size[0], max_size[1] / img.size[1])
            new_size = (int(img.size[0] * ratio), int(img.size[1] * ratio))
            
            # Redimensionar
            optimized_img = img.resize(new_size, Image.Resampling.LANCZOS)
            logger.info(f"📏 Página {i+1} redimensionada: {img.size} → {new_size}")
            
            optimized.append(optimized_img)
        else:
            optimized.append(img)
    
    return optimized

def estimate_processing_time(num_pages: int, avg_time_per_page: float = 15.0) -> float:
    """
    Estima tempo de processamento baseado no número de páginas
    
    Args:
        num_pages: Número de páginas
        avg_time_per_page: Tempo médio por página em segundos
    
    Returns:
        Tempo estimado em segundos
    """
    return num_pages * avg_time_per_page

def check_processing_limits(num_pages: int, max_pages: int = 10) -> bool:
    """
    Verifica se o número de páginas está dentro dos limites
    
    Args:
        num_pages: Número de páginas a processar
        max_pages: Limite máximo de páginas
    
    Returns:
        True se dentro do limite, False caso contrário
    """
    if num_pages > max_pages:
        logger.warning(f"⚠️ BMG - Muitas páginas: {num_pages} > {max_pages}")
        return False
    
    return True 