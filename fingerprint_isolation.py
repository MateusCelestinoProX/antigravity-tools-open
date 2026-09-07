#!/usr/bin/env python3
"""
fingerprint_isolation.py - Módulo de Isolamento Criptográfico de Hardware Fingerprint
Garante que cada conta opere com uma identidade de hardware independente, mitigando
a correlação de contas e o risco de flags/banimentos pelo Google.
"""
import sys
import json
import uuid
import random
import string
from pathlib import Path

def random_hex(length):
    chars = string.ascii_lowercase + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

def new_standard_machine_id():
    # Padrão macOS UUIDv4: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx (y em 8..b)
    hex_chars = '0123456789abcdef'
    y_chars = '89ab'
    parts = []
    for ch in 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx':
        if ch == '-' or ch == '4':
            parts.append(ch)
        elif ch == 'x':
            parts.append(random.choice(hex_chars))
        elif ch == 'y':
            parts.append(random.choice(y_chars))
    return ''.join(parts)

def generate_profile():
    return {
        'machine_id': f'auth0|user_{random_hex(32)}',
        'mac_machine_id': new_standard_machine_id(),
        'dev_device_id': str(uuid.uuid4()),
        'sqm_id': f'{{{str(uuid.uuid4()).upper()}}}'
    }

def get_accounts_dir():
    host_dir = Path.home() / ".antigravity_tools" / "accounts"
    if host_dir.exists():
        return host_dir
    return None

def audit_accounts(apply_fix=False):
    accounts_dir = get_accounts_dir()
    if not accounts_dir or not accounts_dir.exists():
        print(f"Diretório de contas não encontrado em: {accounts_dir}")
        return

    files = list(accounts_dir.glob("*.json"))
    print(f"Auditando {len(files)} contas cadastradas...\n")
    print(f"{'ARQUIVO':<40} {'STATUS':<20} {'MACHINE ID'}")
    print("-" * 80)

    fixed_count = 0
    protected_count = 0

    for f in files:
        try:
            data = json.loads(f.read_text())
            prof = data.get("device_profile")
            if prof and prof.get("mac_machine_id"):
                protected_count += 1
                print(f"{f.name:<40} {'[OK] ISOLADO':<20} {prof.get('mac_machine_id')[:18]}...")
            else:
                if apply_fix:
                    new_prof = generate_profile()
                    data["device_profile"] = new_prof
                    f.write_text(json.dumps(data, indent=2))
                    fixed_count += 1
                    print(f"{f.name:<40} {'[CORRIGIDO]':<20} {new_prof['mac_machine_id'][:18]}...")
                else:
                    print(f"{f.name:<40} {'[VULNERÁVEL]':<20} Sem perfil isolado")
        except Exception as e:
            print(f"{f.name:<40} [ERRO] {e}")

    print("\nResumo da Auditoria:")
    print(f"  - Contas protegidas: {protected_count}")
    if apply_fix:
        print(f"  - Contas corrigidas agora: {fixed_count}")
    print(f"  - Total auditado: {len(files)}")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "apply":
        audit_accounts(apply_fix=True)
    else:
        print("Modo de Auditoria (para corrigir contas sem perfil, use: python3 fingerprint_isolation.py apply):\n")
        audit_accounts(apply_fix=False)
