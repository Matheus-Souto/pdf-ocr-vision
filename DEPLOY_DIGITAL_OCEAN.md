# 🌊 Deploy na Digital Ocean

## Pré-requisitos

- Conta na Digital Ocean
- Droplet criado (Ubuntu 20.04+ recomendado)
- Docker instalado no droplet

## 🚀 Método 1: Service Account Key (Mais Simples)

### 1. Preparar o projeto localmente

```bash
# No Windows, zipar o projeto
# Ou usar git push para um repositório
```

### 2. No droplet Digital Ocean

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Fazer logout e login novamente
exit
```

### 3. Fazer upload do projeto

```bash
# Opção A: Via Git
git clone https://github.com/seu-usuario/seu-repo.git
cd pdf-ocr-vision

# Opção B: Via SCP (do Windows)
scp -r ./pdf-ocr-vision user@ip-do-servidor:/home/user/
```

### 4. Configurar credenciais

```bash
# Fazer upload do secret.json
# Criar arquivo .env
echo "GOOGLE_APPLICATION_CREDENTIALS=secret.json" > .env
```

### 5. Build e Run

```bash
# Build da imagem
docker build -t pdf-ocr-api .

# Executar container
docker run -d \
  --name pdf-ocr-api \
  -p 80:8000 \
  -v $(pwd):/app \
  pdf-ocr-api
```

## 🔧 Método 2: Configuração Visual com gcloud

### 1. Build da imagem

```bash
docker build -t pdf-ocr-api .
```

### 2. Executar container interativo para configuração

```bash
docker run -it \
  --name pdf-setup \
  -p 80:8000 \
  -v $(pwd):/app \
  pdf-ocr-api bash
```

### 3. Dentro do container, executar setup

```bash
# Dar permissão ao script
chmod +x setup_gcloud_docker.sh

# Executar configuração
./setup_gcloud_docker.sh
```

### 4. Seguir os passos interativos

- O script mostrará URLs para login no Google
- Copie as URLs e abra no seu navegador (Windows)
- Faça login com sua conta Google
- Copie o código de autorização de volta para o terminal

### 5. Depois da configuração, executar a API

```bash
python main.py
```

### 6. Para produção, criar nova imagem com credenciais

```bash
# Em outro terminal, commitar o container configurado
docker commit pdf-setup pdf-ocr-api-configured

# Parar container de setup
docker stop pdf-setup

# Executar versão configurada
docker run -d \
  --name pdf-ocr-production \
  -p 80:8000 \
  --restart unless-stopped \
  pdf-ocr-api-configured python main.py
```

## 🌐 Configuração de Firewall

```bash
# Permitir tráfego na porta 80
sudo ufw allow 80
sudo ufw enable
```

## 📝 Verificar se está funcionando

```bash
# Testar localmente no servidor
curl http://localhost/health

# Testar do Windows
curl http://IP-DO-SERVIDOR/health
```

## 🔄 Atualizações

Para atualizar o código:

```bash
# Parar container
docker stop pdf-ocr-production

# Atualizar código (git pull ou novo upload)
git pull

# Rebuild
docker build -t pdf-ocr-api .

# Executar novamente
docker run -d \
  --name pdf-ocr-production \
  -p 80:8000 \
  --restart unless-stopped \
  pdf-ocr-api python main.py
```

## 🆘 Troubleshooting

### Verificar logs

```bash
docker logs pdf-ocr-production
```

### Acessar container

```bash
docker exec -it pdf-ocr-production bash
```

### Verificar se porta está aberta

```bash
netstat -tulpn | grep :80
```

## 💡 Dicas

1. **Usar conta pessoal Google** se a organizacional tem restrições
2. **Backup das credenciais** configuradas
3. **Monitorar logs** para debuggar problemas
4. **Usar nginx** como proxy reverso para produção (opcional)
