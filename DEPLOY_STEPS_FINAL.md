# 🚀 Deploy Final - Credenciais Persistentes

## 📋 **Configuração no EasyPanel:**

### **1. Volume:**

```yaml
Name: gcloud-config
Mount Path: /app/gcloud-config
Size: 1GB
```

### **2. Application:**

```yaml
Repository: https://github.com/SEU-USUARIO/pdf-ocr-vision
Branch: main
Build Context: .
Dockerfile: ./Dockerfile
Port: 8000
Volumes:
  - gcloud-config:/app/gcloud-config
```

### **3. Deploy e Configuração:**

#### **3.1 - Deploy a aplicação**

- EasyPanel fará o build automaticamente

#### **3.2 - Configurar credenciais (UMA VEZ APENAS):**

1. **Acesse terminal** do container no EasyPanel
2. **Execute**:
   ```bash
   ./setup_gcloud_persistent.sh
   ```
3. **Siga o processo visual** (copiar URLs, fazer login)
4. **Pronto!** Credenciais salvas no volume

#### **3.3 - Reiniciar aplicação:**

```bash
# As credenciais serão restauradas automaticamente
# Você verá no log:
# ✅ Credenciais encontradas no volume - restaurando...
# ✅ Credenciais restauradas com sucesso!
```

## 🔄 **Como funciona:**

1. **Primeiro boot**: Container pede para configurar credenciais
2. **Setup**: Script salva credenciais no volume `/app/gcloud-config`
3. **Próximos boots**: Entrypoint restaura credenciais automaticamente
4. **Deploy**: Sempre funciona, credenciais persistem

## ✅ **Vantagens:**

- ✅ **Zero configuração** após setup inicial
- ✅ **Credenciais persistem** mesmo com deploy/restart
- ✅ **Volume separado** - seguro e isolado
- ✅ **Auto-restore** na inicialização
- ✅ **Logs claros** do que está acontecendo

## 🆘 **Se algo der errado:**

```bash
# Limpar e reconfigurar:
rm -rf /app/gcloud-config/*
./setup_gcloud_persistent.sh
```

## 📝 **Resumo dos comandos:**

```bash
# Setup inicial (uma vez):
./setup_gcloud_persistent.sh

# Verificar se funciona:
python test_clean.py

# Executar API:
python main.py
```

**Agora funciona para sempre! 🎉**
