# 🛠️ Instalação do Google Cloud CLI

## Windows

### 1. Baixar o instalador

- Acesse: https://cloud.google.com/sdk/docs/install
- Baixe o **Google Cloud CLI Installer**
- Execute o arquivo `.exe`

### 2. Instalar e configurar

```bash
# Após instalação, reinicie o terminal e execute:
gcloud init

# Fazer login
gcloud auth login

# Configurar credenciais para aplicação
gcloud auth application-default login

# Definir projeto
gcloud config set project stable-chain-455617-v1
```

### 3. Testar a API

```bash
# Agora remova a linha do .env:
# GOOGLE_APPLICATION_CREDENTIALS=secret.json

# E execute a API
python main.py
```

## Alternativa: PowerShell

```powershell
# Instalar via Chocolatey (se tiver)
choco install gcloudsdk

# Ou via Scoop
scoop bucket add extras
scoop install gcloud
```

## Verificar instalação

```bash
gcloud version
gcloud auth list
```
