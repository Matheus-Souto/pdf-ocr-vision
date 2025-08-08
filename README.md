# PDF OCR Vision API

API FastAPI para extração de texto de arquivos PDF e imagens usando Google Cloud Vision OCR.

## 🚀 Características

- ✅ Extração de texto de arquivos PDF
- ✅ Extração de texto de imagens (JPG, PNG, GIF, BMP, TIFF)
- ✅ Processamento de páginas específicas
- ✅ API REST com documentação automática
- ✅ Suporte a CORS
- ✅ Validação de arquivos
- ✅ Monitoramento de saúde da aplicação

## 📋 Pré-requisitos

### 1. Python 3.8+

```bash
python --version
```

### 2. Google Cloud Vision API

1. Crie um projeto no [Google Cloud Console](https://console.cloud.google.com/)
2. Ative a API do Vision API
3. Crie uma chave de serviço (Service Account Key)
4. Baixe o arquivo JSON das credenciais

### 3. Poppler (para conversão PDF)

**Windows:**

- Baixe e instale o Poppler: https://poppler.freedesktop.org/
- Adicione o caminho do Poppler ao PATH do sistema

**Linux:**

```bash
sudo apt-get install poppler-utils
```

**macOS:**

```bash
brew install poppler
```

## 🛠️ Instalação e Configuração

### 1. Clone/Baixe o projeto

```bash
cd pdf-ocr-vision
```

### 2. Crie e ative o ambiente virtual

```bash
# Criar ambiente virtual
python -m venv venv

# Ativar (Windows)
venv\Scripts\activate

# Ativar (Linux/macOS)
source venv/bin/activate
```

### 3. Instale as dependências

```bash
pip install -r requirements.txt
```

### 4. Configure as variáveis de ambiente

Crie um arquivo `.env` na raiz do projeto:

```env
# Configurações do Google Cloud Vision
GOOGLE_APPLICATION_CREDENTIALS=caminho/para/suas/credenciais-google.json

# Configurações da API
HOST=0.0.0.0
PORT=8000
DEBUG=True

# Diretório temporário para upload de arquivos
UPLOAD_DIR=temp_uploads

# Configurações opcionais
MAX_FILE_SIZE=52428800
DEFAULT_DPI=300
MAX_PAGES_PER_REQUEST=50
```

### 5. Configurar credenciais do Google Cloud

1. Coloque o arquivo JSON das credenciais do Google Cloud em um local seguro
2. Atualize a variável `GOOGLE_APPLICATION_CREDENTIALS` no arquivo `.env` com o caminho completo para o arquivo

## 🚀 Execução

### Desenvolvimento

```bash
python main.py
```

### Produção

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

## 📖 Documentação da API

Após iniciar o servidor, acesse:

- **Documentação interativa (Swagger):** http://localhost:8000/docs
- **Documentação alternativa (ReDoc):** http://localhost:8000/redoc
- **Health Check:** http://localhost:8000/health

## 🎯 Endpoints

### 1. Informações da API

```
GET /
```

### 2. Verificação de Saúde

```
GET /health
```

### 3. Extrair Texto de PDF

```
POST /extract-text
```

**Parâmetros:**

- `file`: Arquivo PDF (obrigatório)
- `extract_pages`: Páginas específicas, ex: "1,3,5" ou "all" (opcional)

**Exemplo de uso com curl:**

```bash
curl -X POST "http://localhost:8000/extract-text" \
     -H "accept: application/json" \
     -H "Content-Type: multipart/form-data" \
     -F "file=@documento.pdf" \
     -F "extract_pages=1,2,3"
```

### 4. Extrair Texto de Imagem

```
POST /extract-text-image
```

**Parâmetros:**

- `file`: Arquivo de imagem (obrigatório)

**Exemplo de uso com curl:**

```bash
curl -X POST "http://localhost:8000/extract-text-image" \
     -H "accept: application/json" \
     -H "Content-Type: multipart/form-data" \
     -F "file=@imagem.jpg"
```

## 📝 Exemplo de Resposta

### Extração de PDF

```json
{
  "text": "Texto extraído do documento...",
  "confidence": 0.95,
  "pages": [
    {
      "page_number": 1,
      "text": "Texto da página 1...",
      "confidence": 0.95,
      "words_count": 150
    }
  ],
  "total_pages": 1,
  "success": true,
  "message": "Texto extraído com sucesso de 1 página(s)"
}
```

### Extração de Imagem

```json
{
  "text": "Texto extraído da imagem...",
  "confidence": 0.92,
  "words_count": 45,
  "success": true,
  "message": "Texto extraído com sucesso da imagem"
}
```

## 🔧 Configurações Avançadas

### Variáveis de Ambiente

| Variável                         | Descrição                                | Padrão            |
| -------------------------------- | ---------------------------------------- | ----------------- |
| `GOOGLE_APPLICATION_CREDENTIALS` | Caminho para credenciais do Google Cloud | -                 |
| `HOST`                           | Host do servidor                         | `0.0.0.0`         |
| `PORT`                           | Porta do servidor                        | `8000`            |
| `DEBUG`                          | Modo debug                               | `True`            |
| `UPLOAD_DIR`                     | Diretório de uploads temporários         | `temp_uploads`    |
| `MAX_FILE_SIZE`                  | Tamanho máximo do arquivo (bytes)        | `52428800` (50MB) |
| `DEFAULT_DPI`                    | DPI para conversão de PDF                | `300`             |
| `MAX_PAGES_PER_REQUEST`          | Máximo de páginas por requisição         | `50`              |

## 🐳 Docker (Opcional)

### Dockerfile

```dockerfile
FROM python:3.9-slim

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Construir e executar

```bash
docker build -t pdf-ocr-vision .
docker run -p 8000:8000 -v /caminho/para/credenciais:/app/credentials pdf-ocr-vision
```

## 🔍 Troubleshooting

### Erro de credenciais do Google Cloud

```
DefaultCredentialsError: Could not automatically determine credentials
```

**Solução:** Verifique se o arquivo de credenciais existe e o caminho está correto no `.env`

### Erro de conversão PDF

```
PDFInfoNotInstalledError: poppler not installed
```

**Solução:** Instale o Poppler conforme instruções na seção de pré-requisitos

### Erro de memória em PDFs grandes

**Solução:** Processe páginas específicas usando o parâmetro `extract_pages`

## 📊 Limitações

- Tamanho máximo de arquivo: 50MB (configurável)
- Páginas máximas por requisição: 50 (configurável)
- Tipos de arquivo suportados: PDF, JPG, PNG, GIF, BMP, TIFF
- A API do Google Cloud Vision tem limites de uso e cobrança

## 🔐 Segurança

- Configure corretamente as credenciais do Google Cloud
- Use HTTPS em produção
- Implemente autenticação se necessário
- Configure adequadamente o CORS

## 📞 Suporte

Para problemas ou dúvidas:

1. Verifique a documentação
2. Consulte os logs da aplicação
3. Teste o endpoint `/health`

## 📄 Licença

Este projeto está sob a licença MIT.
