#!/usr/bin/env python3
"""
diagnose.py - Diagnóstico do ecossistema Antigravity 2.0 e Antigravity Tools.
Verifica instalação dos apps, configurações anti-ban, credenciais do Keychain
e estado de isolamento das contas.
"""
import os
import sys
import json
import subprocess
import base64
from pathlib import Path

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return 1, "", str(e)

def check_apps():
    print("=== 1. APLICATIVOS INSTALADOS ===")
    app_antigravity = Path("/Applications/Antigravity.app")
    app_tools = Path("/Applications/Antigravity Tools.app")
    app_ide = Path("/Applications/Antigravity IDE.app")
    
    print(f"Antigravity 2.0 (/Applications/Antigravity.app): {'PRESENTE' if app_antigravity.exists() else 'AUSENTE'}")
    if app_antigravity.exists():
        code, out, _ = run_cmd("cat '/Applications/Antigravity.app/Contents/Info.plist' | grep -A1 CFBundleShortVersionString")
        print(f"  Versão: {out.replace('\n', ' ')}")
    
    print(f"Antigravity Tools (/Applications/Antigravity Tools.app): {'PRESENTE' if app_tools.exists() else 'AUSENTE'}")
    print(f"Antigravity IDE Bridge (/Applications/Antigravity IDE.app): {'CONFIGURADO' if app_ide.exists() else 'NÃO INSTALADO'}")

def check_configs():
    print("\n=== 2. CONFIGURAÇÕES LOCAIS & ANTI-BAN ===")
    home = Path.home()
    gui_config_path = home / ".antigravity_tools" / "gui_config.json"
    accounts_path = home / ".antigravity_tools" / "accounts.json"
    
    if gui_config_path.exists():
        try:
            cfg = json.loads(gui_config_path.read_text())
            qp = cfg.get("quota_protection", {})
            print(f"gui_config.json:")
            print(f"  - antigravity_executable: {cfg.get('antigravity_executable')}")
            print(f"  - antigravity_ide_executable: {cfg.get('antigravity_ide_executable')}")
            print(f"  - refresh_interval: {cfg.get('refresh_interval')} minutos {'(Seguro)' if cfg.get('refresh_interval', 0) >= 60 else '(Ruidoso - Recomenda-se >= 60)'}")
            print(f"  - quota_protection: {'HABILITADA (Segura)' if qp.get('enabled') else 'DESABILITADA (Atenção)'} (threshold: {qp.get('threshold_percentage', 0)}%)")
        except Exception as e:
            print(f"  Erro ao ler gui_config.json: {e}")
    else:
        print("  gui_config.json não encontrado")
        
    if accounts_path.exists():
        try:
            acc = json.loads(accounts_path.read_text())
            print(f"accounts.json:")
            print(f"  - total_contas: {len(acc.get('accounts', []))}")
            print(f"  - current_account_id: {acc.get('current_account_id')}")
            print(f"  - current_target_ide: {acc.get('current_target_ide')} (Nativo = None)")
        except Exception as e:
            print(f"  Erro ao ler accounts.json: {e}")
    else:
        print("  accounts.json não encontrado")

def check_keychain():
    print("\n=== 3. KEYCHAIN DO MACOS (CREDENCIAL ATIVA) ===")
    code, out, err = run_cmd("security find-generic-password -s gemini -a antigravity -w 2>&1")
    if code != 0:
        print(f"  Nenhuma credencial 'gemini'/'antigravity' ativa no Keychain: {err}")
    else:
        raw = out.strip()
        if raw.startswith("go-keyring-base64:"):
            b64_part = raw[len("go-keyring-base64:"):]
            try:
                decoded = base64.b64decode(b64_part).decode('utf-8')
                token_data = json.loads(decoded)
                auth_method = token_data.get("auth_method")
                token = token_data.get("token", {})
                refresh = token.get("refresh_token", "")
                expiry = token.get("expiry", "")
                print(f"  Formato válido: go-keyring-base64 (auth_method: {auth_method})")
                print(f"  Expiry: {expiry}")
                print(f"  Refresh Token: {refresh[:8]}...{refresh[-6:] if len(refresh) > 14 else ''}")
            except Exception as e:
                print(f"  Erro ao decodificar base64: {e}")
        else:
            print(f"  Formato desconhecido no Keychain: {raw[:30]}...")

def check_file_credentials():
    print("\n=== 4. ARQUIVOS DE CREDENCIAIS (~/.gemini) ===")
    creds_path = Path.home() / ".gemini" / "oauth_creds.json"
    if creds_path.exists():
        try:
            c = json.loads(creds_path.read_text())
            ref = c.get("refresh_token", "")
            print(f"oauth_creds.json:")
            print(f"  - token_type: {c.get('token_type')}")
            print(f"  - expiry_date: {c.get('expiry_date')}")
            print(f"  - refresh_token: {ref[:8]}...{ref[-6:] if len(ref) > 14 else ''}")
        except Exception as e:
            print(f"  Erro ao ler oauth_creds.json: {e}")
    else:
        print("  oauth_creds.json não existe")

if __name__ == "__main__":
    check_apps()
    check_configs()
    check_keychain()
    check_file_credentials()
