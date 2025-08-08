import os
from pathlib import Path
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

class Settings:
    """Configurações da aplicação"""
    
    # Configurações do Google Cloud Vision
    GOOGLE_APPLICATION_CREDENTIALS = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    
    # Configurações do servidor
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 8000))
    DEBUG = os.getenv("DEBUG", "True").lower() == "true"
    
    # Configurações de upload
    UPLOAD_DIR = os.getenv("UPLOAD_DIR", "temp_uploads")
    MAX_FILE_SIZE = int(os.getenv("MAX_FILE_SIZE", 50 * 1024 * 1024))  # 50MB
    
    # Configurações de processamento
    DEFAULT_DPI = int(os.getenv("DEFAULT_DPI", 300))
    MAX_PAGES_PER_REQUEST = int(os.getenv("MAX_PAGES_PER_REQUEST", 50))
    
    # Tipos de arquivo suportados
    SUPPORTED_PDF_EXTENSIONS = ['.pdf']
    SUPPORTED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff']
    
    def __init__(self):
        # Criar diretório de upload se não existir
        Path(self.UPLOAD_DIR).mkdir(exist_ok=True)
    
    def validate_google_credentials(self) -> bool:
        """Valida se as credenciais do Google Cloud estão configuradas"""
        if not self.GOOGLE_APPLICATION_CREDENTIALS:
            return False
        
        credentials_path = Path(self.GOOGLE_APPLICATION_CREDENTIALS)
        return credentials_path.exists() and credentials_path.is_file()

# Instância global das configurações
settings = Settings() 