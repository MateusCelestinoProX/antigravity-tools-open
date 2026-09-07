# Antigravity Tools Open 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://apple.com)
[![Status: Production](https://img.shields.io/badge/Status-Tested%20%26%20Working-success.svg)]()
[![Privacy: 100% Clean](https://img.shields.io/badge/Privacy-0%20Secrets%20%7C%20Clean-brightgreen.svg)]()

Suíte aberta de modificações, patches de compatibilidade e camada de segurança **Anti-Ban** para transformar a **imagem oficial do Antigravity Tools** (Antigravity Manager v4.6.8+) em um ambiente 100% integrado ao **Google Antigravity 2.0** no macOS.

---

## 🎯 Visão Geral & Reprodução Exata

Com o conteúdo deste repositório, você consegue reproduzir **exatamente** as mesmas alterações e proteções ativas em produção a partir da imagem oficial limpa do aplicativo.

```text
[ Imagem Oficial ]                     [ Mods Antigravity Tools Open ]
lbjlaq/Antigravity-Manager   +   ./install.sh   ───►  • Bridge Nativa macOS (Zero Erro de Startup)
(Antigravity Tools v4.6.8)                            • 100% Isolamento de Hardware Fingerprint
                                                      • Quota Protection & Polling Suave (Anti-Ban)
                                                      • Troca Inteligente via macOS Keychain
                                                      • Mod Visual Translucid Simple Glass
```

---

## 📦 Como Reproduzir a Partir da Imagem Oficial (Passo a Passo)

### 1. Baixar os Aplicativos Oficiais
1. **Antigravity Tools (Imagem Oficial):** Baixe a versão mais recente (v4.6.8+) dos releases oficiais em:
   👉 [github.com/lbjlaq/Antigravity-Manager/releases](https://github.com/lbjlaq/Antigravity-Manager/releases)
   Arraste para `/Applications/Antigravity Tools.app`.
2. **Google Antigravity 2.0:** Certifique-se de que o aplicativo esteja instalado em `/Applications/Antigravity.app`.

### 2. Clonar este Repositório e Rodar o Instalador Unificado
Execute no terminal:

```bash
git clone https://github.com/MateusCelestinoProX/antigravity-tools-open.git
cd antigravity-tools-open
chmod +x install.sh
./install.sh
```

> **Dica (Com Mod Visual Translucid):** Para aplicar automaticamente a interface Liquid Glass & Multi-Light Effects junto com a instalação, adicione a flag `--with-translucid`:
> ```bash
> ./install.sh --with-translucid
> ```

---

## 🛡️ Modificações Incluídas (Deep Dive)

### 1. Bridge de Compatibilidade com macOS LaunchServices (`setup_bridge.sh`)
- **O Problema Original:** O backend Tauri do Antigravity Tools tenta invocar o executável legadado via `open -a "Antigravity IDE"`, resultando no erro em toast vermelho: `Startup failed: Unable to find application named 'Antigravity IDE'`.
- **A Solução:** Um mini applet nativo é gerado em `/Applications/Antigravity IDE.app` com `Info.plist` registrado no LaunchServices (`lsregister`), repassando de forma transparente todas as execuções para `/Applications/Antigravity.app`. Retorno de código `0` garantido.

### 2. Proteção Anti-Ban Suave e Discreta (`fingerprint_isolation.py`)
- **Isolamento de Máquina Criptográfico:** Gera identificadores de hardware únicos por conta (`machine_id`, `mac_machine_id` UUIDv4 Apple, `dev_device_id` e `sqm_id`). Para a Google, cada conta parece estar sendo executada em um Mac físico diferente.
- **Redução de Ruído de Polling (60 min):** O `refresh_interval` é elevado de 15 para 60 minutos, reduzindo em 75% as requisições desnecessárias aos servidores da Google.
- **Quota Protection Ativa (10% Threshold):** Interrompe chamadas antes que modelos atinjam limite extremo, evitando rajadas contínuas de erros `429 (Resource Exhausted)`.
- **Circuit Breaker:** Proteção contra loop de tentativas falhas com backoff exponencial (`[60, 300, 1800, 7200]` segundos).
- **Cooldown Suave:** Transições com sinal `SIGTERM` (-15) e cooldown de 2 segundos para encerramento gracioso de conexões HTTP/2 e gRPC.

### 3. CLI de Troca Inteligente de Contas (`switch_sync_bridge.py`)
- Injeta credenciais no **macOS Keychain** (`service: gemini`, `account: antigravity`) no padrão RFC3339 `go-keyring-base64:`.
- Mantém `~/.gemini/oauth_creds.json` sincronizado para compatibilidade com o CLI `agy`.
- Permite listar e alternar contas diretamente pelo terminal:
  ```bash
  python3 switch_sync_bridge.py list
  python3 switch_sync_bridge.py switch <email_ou_id>
  ```

### 4. Scanner de Diagnóstico do Ecossistema (`diagnose.py`)
- Inspeciona os caminhos dos aplicativos instalados, integridade do LaunchServices, configurações ativas, chaves do Keychain e tokens do sistema.
  ```bash
  python3 diagnose.py
  ```

### 5. Mod Visual Translucid Simple Glass (`translucid/`)
- Injeta estilos CSS translúcidos (`backdrop-filter: blur(25px)`), orbs de plasma e temas personalizados no WebView do Tauri (`patch-engine.js` e `patch-native-bin.js`).

---

## 🗂️ Estrutura do Repositório

```text
antigravity-tools-open/
├── .gitignore                      # Bloqueio estrito de contas, credenciais e dbs
├── LICENSE                         # Licença MIT oficial (Mateus Celestino)
├── README.md                       # Documentação técnica completa
├── install.sh                      # Instalador mestre unificado (1 comando)
├── setup_bridge.sh                 # Bridge LaunchServices do Antigravity IDE
├── switch_sync_bridge.py           # CLI de troca de contas com Keychain e cooldown
├── diagnose.py                     # Scanner de saúde do ecossistema local
├── fingerprint_isolation.py        # Isolamento de hardware fingerprint único
├── config/
│   ├── accounts.template.json      # Modelo de contas limpo sem dados sensíveis
│   └── gui_config.template.json    # Configurações otimizadas e seguras anti-ban
└── translucid/
    ├── apply-translucid.sh         # Script de aplicação do Liquid Glass
    ├── patch-engine.js             # Engine de injeção de CSS e animações
    ├── patch-native-bin.js         # Patcher de binário Mach-O do app macOS
    └── dist/                       # Frontend estático Vite customizado
```

---

## 🎯 Guia de Botões no Antigravity Tools

Na janela principal (coluna Ações):
- **1º Botão (Setas Retas `ArrowRightLeft` - Recomendado):** Troca para o Antigravity 2.0 Nativo via Keychain e `oauth_creds.json`.
- **2º Botão (Setas Circulares `Repeat2`):** Redirecionado suavemente para o Antigravity sem erro de inicialização.
- **3º Botão (Terminal `Terminal`):** Troca voltada para o CLI `agy`.
- **Smart Switch (Dashboard):** Opera automaticamente com o pipeline nativo do Antigravity 2.0.

---

## 🔒 Privacidade e Segurança de Dados

> [!IMPORTANT]
> Este repositório é 100% open-source e livre de dados pessoais. Não contém credenciais, tokens OAuth, emails privados, bancos de dados SQLite ou cookies de sessão.
> O backup dos dados pessoais de produção é mantido estritamente em repositório privado isolado (`antigravity-tools-closed`).

---

## 📄 Licença

Distribuído sob a licença **MIT**. Consulte o arquivo [LICENSE](LICENSE) para obter mais informações.

Desenvolvido por **[Mateus Celestino](https://github.com/MateusCelestinoProX)**.
