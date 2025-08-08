# 🚀 Deploy Persistente na Digital Ocean

Este guia mostra como fazer deploy da API com **credenciais persistentes** que não se perdem quando o container reinicia.

## 🔧 **Método com Volumes Persistentes**

### **📋 Passo 1: Configurar Volume no EasyPanel**

#### **1.1 - Criar Volume:**

1. No **EasyPanel**, vá para sua aplicação
2. Clique em **"Volumes"** ou **"Storage"**
3. Clique **"Add Volume"**
4. Configure:
   ```yaml
   Name: gcloud-credentials
   Mount Path: /app/credentials
   Size: 1GB (suficiente para credenciais)
   ```

#### **1.2 - Configurar Application:**

```yaml
Repository: https://github.com/SEU-USUARIO/pdf-ocr-vision
Branch: main
Build Context: .
Dockerfile: ./Dockerfile
Port: 8000
Volumes:
  - gcloud-credentials:/app/credentials
```

### **📋 Passo 2: Deploy e Configuração Inicial**

#### **2.1 - Fazer Deploy:**

1. **Deploy** a aplicação no EasyPanel
2. Aguarde o build terminar
3. **NÃO inicie** a aplicação ainda

#### **2.2 - Configurar Credenciais (Uma única vez):**

1. Acesse o **terminal** da aplicação no EasyPanel
2. Execute o script de configuração persistente:

   ```bash
   chmod +x setup_gcloud_persistent.sh
   ./setup_gcloud_persistent.sh
   ```

3. **Siga o processo visual:**
   - Copie a URL que aparece
   - Abra no navegador
   - Faça login no Google
   - Copie o código de volta
   - Repita para Application Default Credentials

#### **2.3 - Verificar Persistência:**

```bash
# Verificar se as credenciais estão no volume
ls -la /app/credentials/

# Deve mostrar algo como:
# application_default_credentials.json
# configurations/
# logs/
```

### **📋 Passo 3: Iniciar Aplicação**

#### **3.1 - Executar API:**

```bash
python main.py
```

#### **3.2 - Verificar Funcionamento:**

```bash
# Testar health
curl http://localhost:8000/health

# Deve retornar:
# {"status":"healthy","google_vision":"connected","upload_dir":true}
```

### **📋 Passo 4: Testar Persistência**

#### **4.1 - Simular Restart:**

1. **Pare** a aplicação (Ctrl+C)
2. **Reinicie** o container no EasyPanel
3. **Execute** novamente:
   ```bash
   python main.py
   ```

#### **4.2 - Verificar Credenciais:**

```bash
# As credenciais devem ainda estar lá
python test_clean.py

# Deve mostrar:
# ✅ Cliente criado com sucesso!
# ❌ Erro: 400 Request must specify image and features.
# (Isso é NORMAL - significa que funcionou!)
```

## 🔄 **Vantagens do Método Persistente:**

✅ **Credenciais preservadas** após restart  
✅ **Deploy automático** funciona  
✅ **Zero configuração** após setup inicial  
✅ **Backup** das credenciais no volume  
✅ **Escalabilidade** mantida

## 🆘 **Troubleshooting:**

### **Problema: Volume não monta**

```bash
# Verificar se o diretório existe
ls -la /app/credentials/

# Se não existir, criar manualmente
mkdir -p /app/credentials
```

### **Problema: Credenciais corrompidas**

```bash
# Limpar credenciais e reconfigurar
rm -rf /app/credentials/*
./setup_gcloud_persistent.sh
```

### **Problema: Permissões**

```bash
# Corrigir permissões
chmod 600 /app/credentials/application_default_credentials.json
chown -R root:root /app/credentials/
```

## 📝 **Resumo dos Comandos:**

```bash
# 1. Setup inicial (uma vez só)
chmod +x setup_gcloud_persistent.sh
./setup_gcloud_persistent.sh

# 2. Executar API
python main.py

# 3. Testar
curl http://localhost:8000/health
python test_clean.py
```

## 🎯 **Próximos Passos:**

1. ✅ Configure o volume no EasyPanel
2. ✅ Faça deploy da aplicação
3. ✅ Execute o setup das credenciais
4. ✅ Teste a persistência
5. ✅ Configure domínio/DNS
6. ✅ Monitor logs e performance

**Agora suas credenciais ficam salvas permanentemente!** 🎉
