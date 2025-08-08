#!/usr/bin/env python3
"""
Script para configurar automaticamente o quota project do Google Cloud
"""

import subprocess
import os
import sys

def run_command(cmd):
    """Executa comando e retorna resultado"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except Exception as e:
        return False, "", str(e)

def fix_quota_project():
    """Configura o quota project automaticamente"""
    print("🔧 Configurando quota project automaticamente...")
    
    # 1. Verificar se gcloud está configurado
    success, output, error = run_command("gcloud config get-value core/project")
    
    if success and output and output != "(unset)":
        project_id = output
        print(f"✅ Projeto encontrado: {project_id}")
    else:
        # Tentar usar o projeto padrão configurado
        project_id = "stable-chain-455617-v1"  # Seu projeto
        print(f"⚙️ Configurando projeto padrão: {project_id}")
        
        success, _, error = run_command(f"gcloud config set project {project_id}")
        if not success:
            print(f"❌ Erro ao configurar projeto: {error}")
            return False
    
    # 2. Configurar quota project para ADC
    print("🎯 Configurando quota project para Application Default Credentials...")
    success, _, error = run_command(f"gcloud auth application-default set-quota-project {project_id}")
    
    if success:
        print(f"✅ Quota project configurado: {project_id}")
        
        # 3. Definir variável de ambiente
        os.environ["GOOGLE_CLOUD_PROJECT"] = project_id
        print(f"✅ Variável GOOGLE_CLOUD_PROJECT definida: {project_id}")
        
        return True
    else:
        print(f"❌ Erro ao configurar quota project: {error}")
        return False

def test_vision_api():
    """Testa se a Vision API está funcionando"""
    print("🧪 Testando Vision API...")
    
    try:
        from google.cloud import vision
        client = vision.ImageAnnotatorClient()
        print("✅ Cliente Vision criado com sucesso!")
        return True
    except Exception as e:
        print(f"❌ Erro ao criar cliente Vision: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Auto-configuração do Google Cloud Vision")
    print("=" * 45)
    
    # Configurar quota project
    if fix_quota_project():
        # Testar API
        if test_vision_api():
            print("\n🎉 Configuração concluída com sucesso!")
            print("💡 A API está pronta para usar!")
            sys.exit(0)
        else:
            print("\n⚠️ Quota project configurado, mas API ainda com problema")
            sys.exit(1)
    else:
        print("\n❌ Falha na configuração do quota project")
        sys.exit(1) 