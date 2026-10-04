#!/data/data/com.termux/files/usr/bin/bash

# Takeshi Bot - instalador para Termux
# Uso: bash install.sh

set -Eeuo pipefail

APP_NAME="Takeshi Bot"
MIN_NODE_MAJOR=22
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { printf "${CYAN}[%s]${NC} %s\n" "Takeshi" "$1"; }
ok()   { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}!${NC} %s\n" "$1"; }
fail() { printf "${RED}✗${NC} %s\n" "$1" >&2; exit 1; }

trap 'echo; fail "O instalador encontrou um erro na linha $LINENO."' ERR

clear 2>/dev/null || true
printf "\n${CYAN}========================================${NC}\n"
printf "${CYAN}        %s — INSTALAÇÃO TERMUX${NC}\n" "$APP_NAME"
printf "${CYAN}========================================${NC}\n\n"

[ -f "$ROOT_DIR/package.json" ] || fail "package.json não encontrado. Execute o install.sh dentro da pasta do Takeshi Bot."
command -v pkg >/dev/null 2>&1 || fail "Este instalador foi feito para Termux."

cd "$ROOT_DIR"

log "Atualizando os pacotes do Termux..."
pkg update -y

log "Instalando dependências do sistema..."
# nodejs-lts é preferido; se não existir na instalação do Termux, tenta nodejs.
if ! command -v node >/dev/null 2>&1; then
    if pkg install -y nodejs-lts git unzip; then
        :
    else
        pkg install -y nodejs git unzip
    fi
else
    pkg install -y git unzip
fi

command -v node >/dev/null 2>&1 || fail "Node.js não foi instalado."
command -v npm >/dev/null 2>&1 || fail "npm não foi instalado com o Node.js."

NODE_VERSION="$(node -p 'process.versions.node')"
NODE_MAJOR="$(node -p 'Number(process.versions.node.split(".")[0])')"
printf "Node.js: %s\n" "$NODE_VERSION"
printf "npm: %s\n\n" "$(npm --version)"

if [ "$NODE_MAJOR" -lt "$MIN_NODE_MAJOR" ]; then
    fail "Node.js $MIN_NODE_MAJOR ou superior é necessário. Versão encontrada: $NODE_VERSION"
fi

ok "Node.js compatível encontrado."

log "Preparando arquivos de configuração..."
if [ -f .env ]; then
    ok ".env existente preservado."
elif [ -f .env.example ]; then
    cp .env.example .env
    ok ".env criado a partir de .env.example."
    warn "Revise o arquivo .env e coloque somente as chaves que você realmente usa."
else
    cat > .env <<'ENVEOF'
BOT_NAME=Takeshi Bot
BOT_PREFIX=/
BOT_LID=
OWNER_LID=
SPIDER_API_TOKEN=
LINKER_API_KEY=
OPENAI_API_KEY=
DEVELOPER_MODE=false
EVENT_TIMEOUT_MS=500
ENVEOF
    ok ".env básico criado."
fi

log "Instalando dependências do projeto..."
if [ -f package-lock.json ]; then
    npm ci --omit=dev
else
    npm install --omit=dev
fi

ok "Dependências instaladas."

# Corrige permissões dos scripts auxiliares sem alterar o conteúdo deles.
chmod +x install.sh 2>/dev/null || true
chmod +x update.sh reset-qr-auth.sh 2>/dev/null || true

# Evita que o Android mate processos em segundo plano tão facilmente quando possível.
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock || true
    ok "Wake lock do Termux ativado."
else
    warn "termux-api não está disponível; o bot ainda pode funcionar normalmente."
fi

printf "\n${GREEN}========================================${NC}\n"
printf "${GREEN}        INSTALAÇÃO CONCLUÍDA!${NC}\n"
printf "${GREEN}========================================${NC}\n\n"

printf "${CYAN}Para iniciar:${NC}\n"
printf "  cd %q\n" "$ROOT_DIR"
printf "  npm start\n\n"
printf "${CYAN}Para testar sem iniciar o bot:${NC}\n"
printf "  npm test\n\n"
printf "${CYAN}Para atualizar:${NC}\n"
printf "  ./update.sh\n\n"
printf "${CYAN}Para resetar a autenticação:${NC}\n"
printf "  ./reset-qr-auth.sh\n\n"

if [ -f .env ]; then
    warn "Antes de usar recursos que dependem de API, confira o .env. Não compartilhe esse arquivo."
fi

read -r -p "Deseja iniciar o Takeshi Bot agora? [S/n]: " START_NOW
START_NOW="${START_NOW:-S}"

case "$START_NOW" in
    [SsYy]*)
        printf "\n${CYAN}Iniciando %s...${NC}\n\n" "$APP_NAME"
        exec npm start
        ;;
    *)
        ok "Instalação finalizada sem iniciar o bot."
        ;;
esac
