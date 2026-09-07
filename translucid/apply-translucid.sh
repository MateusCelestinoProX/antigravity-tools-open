#!/bin/bash
set -e

# ==============================================================================
#  💎 TRANSLUCID ANTIGRAVITY TOOLS — SIMPLE GLASS + MULTI-LIGHT EFFECTS
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="/Applications/Antigravity Tools.app"
USER_CONFIG_DIR="$HOME/.antigravity_tools"
TARGET_DIST="$USER_CONFIG_DIR/dist"

echo "🔮 [Translucid Antigravity Tools] Iniciando processo de personalização visual..."

# 1. Obter assets se não existirem
if [ ! -d "$SCRIPT_DIR/dist" ]; then
    echo "📦 Baixando assets visuais do Translucid..."
    curl -sL https://github.com/MateusCelestinoProX/translucid-antigravity-tools/archive/refs/heads/main.zip -o /tmp/translucid.zip
    unzip -q -o /tmp/translucid.zip -d /tmp/
    cp -r /tmp/translucid-antigravity-tools-main/dist "$SCRIPT_DIR/dist"
    rm -rf /tmp/translucid.zip /tmp/translucid-antigravity-tools-main
fi

# 2. Encerrar instâncias ativas
echo "🛑 Encerrando instâncias em execução do Antigravity Tools..."
killall antigravity-tools 2>/dev/null || true
killall antigravity-tools-bin 2>/dev/null || true
sleep 1

# 3. Injetar regras de Simple Glass e Light Effects no dist web
echo "💉 Sincronizando e injetando regras de vidro no dist web..."
node "$SCRIPT_DIR/patch-engine.js" "$SCRIPT_DIR/dist"
mkdir -p "$USER_CONFIG_DIR"
rm -rf "$TARGET_DIST"
cp -r "$SCRIPT_DIR/dist" "$TARGET_DIST"

# 4. Injetar regras no binário nativo do App macOS
if [ -d "$APP_PATH" ]; then
  echo "💉 Injetando Simple Glass + Light Effects no binário nativo do macOS..."
  node "$SCRIPT_DIR/patch-native-bin.js"

  MACOS_DIR="$APP_PATH/Contents/MacOS"
  BIN_PATH="$MACOS_DIR/antigravity-tools"
  REAL_BIN="$MACOS_DIR/antigravity-tools-bin"

  if [ -f "$BIN_PATH" ] && file "$BIN_PATH" | grep -q "Mach-O"; then
    mv "$BIN_PATH" "$REAL_BIN"
  fi

  cat << 'EOS' > "$BIN_PATH"
#!/bin/bash
export ABV_DIST_PATH="$HOME/.antigravity_tools/dist"
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$DIR/antigravity-tools-bin" ]; then
  exec "$DIR/antigravity-tools-bin" "$@"
else
  exec "$DIR/antigravity-tools" "$@"
fi
EOS
  chmod +x "$BIN_PATH"
  chmod +x "$REAL_BIN" 2>/dev/null || true

  echo "🛡️ Reassinando aplicativo e limpando quarentena Gatekeeper..."
  xattr -cr "$APP_PATH" 2>/dev/null || true
  codesign --force --deep --sign - "$APP_PATH" 2>/dev/null || true

  echo "🚀 Abrindo Antigravity Tools Desktop..."
  open "$APP_PATH" || true
fi

echo ""
echo "✨ [Sucesso!] Antigravity Tools agora possui interface Simple Glass + Multi-Light Effects!"
echo "🌐 Acesso Web: http://127.0.0.1:8045/"
echo ""
