#!/usr/bin/env python3
"""
switch_sync_bridge.py - Bridge e Utilitário de Troca e Sincronização Inteligente
para Antigravity 2.0 (macOS Keychain + ~/.gemini/oauth_creds.json).
Inclui proteção anti-ban (fingerprint isolado) e cooldown suave.
"""
import os
import sys
import json
import base64
import time
import datetime
import subprocess
from pathlib import Path

HOST_DATA_DIR = Path.home() / ".antigravity_tools"
ACCOUNTS_DIR = HOST_DATA_DIR / "accounts"
ACCOUNTS_JSON = HOST_DATA_DIR / "accounts.json"
GEMINI_CREDS = Path.home() / ".gemini" / "oauth_creds.json"

def run_cmd(cmd):
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return res.returncode, res.stdout.strip(), res.stderr.strip()

def list_accounts():
    if not ACCOUNTS_JSON.exists():
        print(f"Erro: {ACCOUNTS_JSON} não encontrado.")
        return []
    
    data = json.loads(ACCOUNTS_JSON.read_text())
    accounts = data.get("accounts", [])
    current_id = data.get("current_account_id")
    
    print(f"\nFonte de Contas: {ACCOUNTS_JSON}")
    print(f"Total de contas: {len(accounts)} (Conta Ativa: {current_id})\n")
    print(f"{'#':<3} {'EMAIL':<36} {'STATUS':<10} {'FINGERPRINT ANTI-BAN':<22} {'ID'}")
    print("-" * 115)
    for idx, acc in enumerate(accounts, 1):
        is_curr = " (ATIVA)" if acc.get("id") == current_id else ""
        status = "DESATIVADA" if acc.get("disabled") else "ATIVA"
        
        acc_file = ACCOUNTS_DIR / f"{acc.get('id')}.json"
        fp_status = "SEM PERFIL"
        if acc_file.exists():
            try:
                acc_data = json.loads(acc_file.read_text())
                if acc_data.get("device_profile"):
                    mid = acc_data["device_profile"].get("mac_machine_id", "")
                    fp_status = f"ISOLADO ({mid[:8]}...)"
            except Exception:
                pass

        print(f"{idx:<3} {acc.get('email', ''):<36} {status + is_curr:<10} {fp_status:<22} {acc.get('id')}")
    return accounts

def switch_to_account(account_id_or_email, restart_app=True, cooldown=2.0):
    if not ACCOUNTS_JSON.exists():
        print("Erro: accounts.json não encontrado.")
        return False
        
    index_data = json.loads(ACCOUNTS_JSON.read_text())
    matched_id = None
    matched_email = None
    
    for acc in index_data.get("accounts", []):
        if acc.get("id") == account_id_or_email or acc.get("email") == account_id_or_email:
            matched_id = acc.get("id")
            matched_email = acc.get("email")
            break
            
    if not matched_id:
        print(f"Conta '{account_id_or_email}' não encontrada!")
        return False
        
    acc_file = ACCOUNTS_DIR / f"{matched_id}.json"
    if not acc_file.exists():
        print(f"Arquivo de conta {acc_file} não encontrado!")
        return False
        
    account = json.loads(acc_file.read_text())
    token = account.get("token", {})
    access_token = token.get("access_token", "")
    refresh_token = token.get("refresh_token", "")
    expiry_ts = token.get("expiry_timestamp", 0)
    id_token = token.get("id_token")
    device_prof = account.get("device_profile")
    
    if not refresh_token:
        print(f"Erro: refresh_token ausente para {matched_email}!")
        return False

    # 1. Formatar data ISO/RFC3339 com microssegundos para o Keychain
    if expiry_ts > 10_000_000_000:
        dt = datetime.datetime.fromtimestamp(expiry_ts / 1000.0, datetime.timezone.utc)
    else:
        dt = datetime.datetime.fromtimestamp(expiry_ts, datetime.timezone.utc)
    expiry_rfc3339 = dt.strftime("%Y-%m-%dT%H:%M:%S.%fZ")

    # 2. Montar KeyringPayload
    payload = {
        "token": {
            "access_token": access_token,
            "token_type": "Bearer",
            "refresh_token": refresh_token,
            "expiry": expiry_rfc3339
        },
        "auth_method": "consumer"
    }
    payload_json = json.dumps(payload, separators=(',', ':'))
    b64_val = base64.b64encode(payload_json.encode('utf-8')).decode('utf-8')
    keyring_secret = f"go-keyring-base64:{b64_val}"

    print(f"Aplicando credenciais para: {matched_email} ({matched_id})...")
    if device_prof:
        print(f"  ✓ Fingerprint de máquina isolado ativo: {device_prof.get('mac_machine_id')}")

    # 3. Injetar no macOS Keychain
    run_cmd("security delete-generic-password -s gemini -a antigravity 2>/dev/null")
    code, _, err = run_cmd(f'security add-generic-password -s gemini -a antigravity -w "{keyring_secret}" -A')
    if code != 0:
        print(f"Falha ao salvar no Keychain do macOS: {err}")
        return False
    print("  ✓ Keychain do macOS atualizado com sucesso!")

    # 4. Injetar em ~/.gemini/oauth_creds.json
    expiry_ms = int(dt.timestamp() * 1000)
    oauth_creds_payload = {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "Bearer",
        "expiry_date": expiry_ms,
        "id_token": id_token,
        "scope": "https://www.googleapis.com/auth/userinfo.email openid https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/userinfo.profile"
    }
    try:
        GEMINI_CREDS.parent.mkdir(parents=True, exist_ok=True)
        GEMINI_CREDS.write_text(json.dumps(oauth_creds_payload, indent=2))
        print(f"  ✓ {GEMINI_CREDS} atualizado com sucesso!")
    except Exception as e:
        print(f"  Aviso: Não foi possível gravar {GEMINI_CREDS}: {e}")

    # 5. Atualizar current_account_id e current_target_ide
    try:
        index_data["current_account_id"] = matched_id
        index_data["current_target_ide"] = None
        ACCOUNTS_JSON.write_text(json.dumps(index_data, indent=2))
        print(f"  ✓ accounts.json atualizado (current_target_ide = null)!")
    except Exception as e:
        print(f"  Aviso: Não foi possível salvar accounts.json: {e}")

    # 6. Reiniciar o Antigravity com Cooldown suave (anti-burst)
    if restart_app:
        print("Executando transição suave do Antigravity 2.0...")
        code, out, _ = run_cmd("pgrep -f '/Applications/Antigravity.app/Contents/MacOS/Antigravity' | head -n 1")
        if out:
            main_pid = out.strip()
            print(f"  Enviando SIGTERM gracioso para o processo {main_pid}...")
            run_cmd(f"kill -15 {main_pid}")
            print(f"  Aguardando cooldown discreto ({cooldown}s) para liberação de conexões...")
            time.sleep(cooldown)
        run_cmd("open -a '/Applications/Antigravity.app'")
        print("  ✓ Antigravity 2.0 reaberto com a nova conta e novo fingerprint!")

    print(f"\n[SUCESSO] Conta ativada de forma segura: {matched_email}")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] == "list":
        list_accounts()
    elif sys.argv[1] == "switch" and len(sys.argv) >= 3:
        target = sys.argv[2]
        no_restart = "--no-restart" in sys.argv
        switch_to_account(target, restart_app=not no_restart)
    else:
        print("Uso:")
        print("  python3 switch_sync_bridge.py list")
        print("  python3 switch_sync_bridge.py switch <email_ou_id> [--no-restart]")
