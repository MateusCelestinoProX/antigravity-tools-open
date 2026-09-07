#!/usr/bin/env bash
set -euo pipefail

echo "================================================================"
echo " Antigravity 2.0 Tools Bridge - Instalador Automatizado (macOS)"
echo "================================================================"

# 1. Checar se o Antigravity 2.0 está instalado
ANTIGRAVITY_APP="/Applications/Antigravity.app"
if [ ! -d "$ANTIGRAVITY_APP" ]; then
    echo "[-] Erro: $ANTIGRAVITY_APP não foi encontrado em /Applications."
    echo "    Certifique-se de que o Antigravity 2.0 está instalado."
    exit 1
fi

echo "[+] Antigravity 2.0 detectado em: $ANTIGRAVITY_APP"

# 2. Criar o Applet Bridge Antigravity IDE.app
BRIDGE_APP="/Applications/Antigravity IDE.app"
echo "[+] Configurando Bridge de Compatibilidade: $BRIDGE_APP..."

rm -rf "$BRIDGE_APP"
mkdir -p "$BRIDGE_APP/Contents/MacOS"

cat << 'EOS' > "$BRIDGE_APP/Contents/MacOS/Antigravity IDE"
#!/bin/bash
exec /usr/bin/open -a "/Applications/Antigravity.app" "$@"
EOS
chmod +x "$BRIDGE_APP/Contents/MacOS/Antigravity IDE"

cat << 'EOS' > "$BRIDGE_APP/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Antigravity IDE</string>
    <key>CFBundleIdentifier</key>
    <string>com.google.antigravity.ide.bridge</string>
    <key>CFBundleName</key>
    <string>Antigravity IDE</string>
    <key>CFBundleDisplayName</key>
    <string>Antigravity IDE</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.12.2</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOS

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$BRIDGE_APP" 2>/dev/null || true
echo "[+] Bridge Applet registrado com sucesso no LaunchServices!"

# 3. Otimizar configurações do Antigravity Tools
CONFIG_DIR="$HOME/.antigravity_tools"
CONFIG_FILE="$CONFIG_DIR/gui_config.json"
ACCOUNTS_FILE="$CONFIG_DIR/accounts.json"

if [ -f "$CONFIG_FILE" ]; then
    echo "[+] Atualizando configurações de segurança em: $CONFIG_FILE..."
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    cfg = json.load(f)
cfg['antigravity_executable'] = '/Applications/Antigravity.app'
cfg['antigravity_ide_executable'] = None
cfg['refresh_interval'] = 60
if 'quota_protection' not in cfg:
    cfg['quota_protection'] = {}
cfg['quota_protection']['enabled'] = True
cfg['quota_protection']['threshold_percentage'] = 10
with open('$CONFIG_FILE', 'w') as f:
    json.dump(cfg, f, indent=2)
print('    ✓ gui_config.json otimizado com proteções anti-ban!')
"
fi

if [ -f "$ACCOUNTS_FILE" ]; then
    echo "[+] Ajustando target padrão em: $ACCOUNTS_FILE..."
    python3 -c "
import json
with open('$ACCOUNTS_FILE') as f:
    acc = json.load(f)
acc['current_target_ide'] = None
with open('$ACCOUNTS_FILE', 'w') as f:
    json.dump(acc, f, indent=2)
print('    ✓ current_target_ide redefinido para Antigravity Nativo!')
"
fi

# 4. Rodar isolamento de fingerprint se houver contas
if [ -d "$CONFIG_DIR/accounts" ]; then
    echo "[+] Verificando isolamento de hardware fingerprint para contas existentes..."
    python3 fingerprint_isolation.py apply || true
fi

echo ""
echo "================================================================"
echo "[SUCESSO] Instalação e configuração concluídas com êxito!"
echo "Agora você pode alternar contas sem erros e com máxima segurança."
echo "================================================================"
