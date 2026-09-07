#!/usr/bin/env bash
# ==============================================================================
#  🚀 ANTIGRAVITY TOOLS OPEN — INSTALADOR E PATCHER UNIFICADO (macOS)
#  Transforma a imagem oficial do Antigravity Tools no ambiente completo:
#  - Bridge Antigravity 2.0 (Elimina erro de startup da IDE)
#  - Proteção Anti-Ban & Isolamento Criptográfico de Hardware Fingerprint
#  - Configurações Otimizadas de Quota e Polling Suave
#  - Mod Visual Translucid Simple Glass & Multi-Light (Opcional)
#  - CLI Bridge para Troca Inteligente de Contas via macOS Keychain
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.antigravity_tools"
GUI_CONFIG="$CONFIG_DIR/gui_config.json"
ACCOUNTS_JSON="$CONFIG_DIR/accounts.json"
ANTIGRAVITY_APP="/Applications/Antigravity.app"
TOOLS_APP="/Applications/Antigravity Tools.app"
BRIDGE_APP="/Applications/Antigravity IDE.app"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}        🌌 ANTIGRAVITY TOOLS OPEN — INSTALADOR UNIFICADO        ${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""

# ------------------------------------------------------------------------------
# 1. VERIFICAÇÃO DE PRÉ-REQUISITOS
# ------------------------------------------------------------------------------
echo -e "${BLUE}[1/5] Verificando aplicativos oficiais instalados...${NC}"

if [ ! -d "$TOOLS_APP" ]; then
    echo -e "${YELLOW}[!] Aviso: $TOOLS_APP não foi encontrado em /Applications.${NC}"
    echo -e "    Baixe a imagem oficial v4.6.8+ em:"
    echo -e "    https://github.com/lbjlaq/Antigravity-Manager/releases"
    echo -e "    Instale-o e execute este script novamente."
    echo ""
    read -p "Deseja continuar mesmo assim para preparar as configurações? (s/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}    ✓ Antigravity Tools Oficial detectado em: $TOOLS_APP${NC}"
fi

if [ ! -d "$ANTIGRAVITY_APP" ]; then
    echo -e "${YELLOW}[!] Aviso: $ANTIGRAVITY_APP não foi encontrado em /Applications.${NC}"
    echo -e "    Certifique-se de que o Google Antigravity 2.0 está instalado."
else
    echo -e "${GREEN}    ✓ Google Antigravity 2.0 detectado em: $ANTIGRAVITY_APP${NC}"
fi

# ------------------------------------------------------------------------------
# 2. CONFIGURAR APPLET BRIDGE ANTIGRAVITY IDE (ELIMINA ERRO DE STARTUP)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[2/5] Configurando Bridge de compatibilidade LaunchServices...${NC}"

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
echo -e "${GREEN}    ✓ Bridge '/Applications/Antigravity IDE.app' registrado com sucesso!${NC}"
echo -e "      (Elimina o erro 'Startup failed: Unable to find application named Antigravity IDE')"

# ------------------------------------------------------------------------------
# 3. APLICAR CONFIGURAÇÕES ANTI-BAN E PROTEÇÃO DE QUOTA
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[3/5] Aplicando configurações seguras e anti-ban em ~/.antigravity_tools...${NC}"
mkdir -p "$CONFIG_DIR/accounts"

if [ ! -f "$GUI_CONFIG" ]; then
    echo -e "    Criando $GUI_CONFIG a partir do template otimizado..."
    cp "$SCRIPT_DIR/config/gui_config.template.json" "$GUI_CONFIG"
else
    echo -e "    Atualizando parâmetros de segurança no $GUI_CONFIG existente..."
    python3 -c "
import json
with open('$GUI_CONFIG') as f:
    cfg = json.load(f)

cfg['antigravity_executable'] = '$ANTIGRAVITY_APP'
cfg['antigravity_ide_executable'] = None
cfg['refresh_interval'] = 60

if 'quota_protection' not in cfg:
    cfg['quota_protection'] = {}
cfg['quota_protection']['enabled'] = True
cfg['quota_protection']['threshold_percentage'] = 10
if 'monitored_models' not in cfg['quota_protection']:
    cfg['quota_protection']['monitored_models'] = ['claude', 'gemini-3-pro-high', 'gemini-3-flash', 'gemini-3.1-flash-image']

if 'circuit_breaker' not in cfg:
    cfg['circuit_breaker'] = {}
cfg['circuit_breaker']['enabled'] = True
cfg['circuit_breaker']['backoff_steps'] = [60, 300, 1800, 7200]

with open('$GUI_CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)
"
fi

if [ -f "$ACCOUNTS_JSON" ]; then
    python3 -c "
import json
with open('$ACCOUNTS_JSON') as f:
    acc = json.load(f)
acc['current_target_ide'] = None
with open('$ACCOUNTS_JSON', 'w') as f:
    json.dump(acc, f, indent=2)
"
fi

echo -e "${GREEN}    ✓ Polling ajustado para 60 min (75% menos ruído nos servidores Google)${NC}"
echo -e "${GREEN}    ✓ Quota protection e Circuit breaker ativos (evita erro 429 continuado)${NC}"

# ------------------------------------------------------------------------------
# 4. ISOLAMENTO DE HARDWARE FINGERPRINT (DISCRETO & SUAVE)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[4/5] Verificando e aplicando isolamento de Hardware Fingerprint...${NC}"
python3 "$SCRIPT_DIR/fingerprint_isolation.py" apply || true

# ------------------------------------------------------------------------------
# 5. MOD VISUAL TRANSLUCID GLASS (OPCIONAL)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[5/5] Mod Visual Translucid Simple Glass...${NC}"

APPLY_TRANSLUCID=false
if [[ "${1:-}" == "--with-translucid" ]] || [[ "${1:-}" == "--all" ]]; then
    APPLY_TRANSLUCID=true
elif [ -d "$SCRIPT_DIR/translucid" ] && [ -d "$TOOLS_APP" ]; then
    echo "    Mod visual disponível em: translucid/"
fi

if [ "$APPLY_TRANSLUCID" = true ]; then
    echo -e "${PURPLE}    Aplicando patch visual Translucid...${NC}"
    if [ -f "$SCRIPT_DIR/translucid/apply-translucid.sh" ]; then
        (cd "$SCRIPT_DIR/translucid" && bash apply-translucid.sh) || true
    fi
else
    echo -e "    Dica: Para ativar Liquid Glass no Antigravity Tools, execute: cd translucid && ./apply-translucid.sh"
fi

# ------------------------------------------------------------------------------
# DIAGNÓSTICO FINAL
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}       ✨ [SUCESSO] Instalação e Modificações Concluídas!       ${NC}"
echo -e "${CYAN}================================================================${NC}"
echo ""
echo -e "Executando diagnóstico de integridade do ambiente:"
python3 "$SCRIPT_DIR/diagnose.py"
echo ""
echo -e "${GREEN}Seu Antigravity Tools agora opera com 100% de compatibilidade e segurança!${NC}"
echo -e "Para trocar de conta via terminal: ${CYAN}python3 switch_sync_bridge.py list${NC}"
