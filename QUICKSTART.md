# 🚀 Guia de Início Rápido

## ⚡ Configuração Mínima (5 minutos)

### 1. Configurar Google Cloud Vision

```bash
# 1. Crie um projeto no Google Cloud Console
# 2. Ative a Vision API
# 3. Crie uma Service Account Key
# 4. Baixe o arquivo JSON das credenciais
```

### 2. Configurar Ambiente

```bash
# Criar arquivo .env
echo 'GOOGLE_APPLICATION_CREDENTIALS=caminho/para/suas/credenciais.json' > .env
echo 'HOST=0.0.0.0' >> .env
echo 'PORT=8000' >> .env
echo 'DEBUG=True' >> .env
```

### 3. Instalar Poppler (Windows)

- Baixe: https://github.com/oschwartz10612/poppler-windows/releases/
- Extraia e adicione ao PATH

### 4. Executar API

```bash
# O ambiente virtual já está ativo
python main.py
```

### 5. Testar

- Abra: http://localhost:8000/docs
- Ou execute: `python test_api.py`

## 🧪 Teste Rápido

```bash
# Testar com curl
curl -X POST "http://localhost:8000/extract-text" \
     -H "Content-Type: multipart/form-data" \
     -F "file=@documento.pdf"
```

## ❌ Problemas Comuns

**Erro de credenciais:**

```
DefaultCredentialsError: Could not automatically determine credentials
```

✅ **Solução:** Verifique o caminho no arquivo .env

**Erro do Poppler:**

```
PDFInfoNotInstalledError: poppler not installed
```

✅ **Solução:** Instale o Poppler e adicione ao PATH

**Erro 503 no /health:**
✅ **Solução:** Verifique as credenciais do Google Cloud

## 🔗 Links Úteis

- Documentação: http://localhost:8000/docs
- Health Check: http://localhost:8000/health
- README completo: [README.md](README.md)
