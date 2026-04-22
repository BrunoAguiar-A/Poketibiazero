#!/bin/bash
# start_protected.sh — inicia o TFS com proteção contra OOM killer
# O OOM score -900 faz o kernel matar OUTROS processos antes do TFS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
mkdir -p logs backups

TFS_BIN="./build/tfs"

LOCK_DIR="/tmp/start_protected_tfs.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "Ja existe uma instancia de start_protected.sh em execucao."
    exit 1
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

echo "Iniciando TFS com proteção OOM..."

# Configura prioridade antes de iniciar
ulimit -c unlimited
set -o pipefail

while true
do
    LOG_FILE="logs/$(date +"%F %H-%M-%S.log")"

    # Inicia o servidor em background para pegar o PID
    gdb --batch -return-child-result --command=antirollback_config --args "$TFS_BIN" \
        2>&1 | awk '{ print strftime("%F %T - "), $0; fflush(); }' | tee "$LOG_FILE" &

    SERVER_PID=$!

    # Aguarda o processo do TFS aparecer e protege apenas o PID mais recente.
    TFS_PID=""
    for _ in $(seq 1 20); do
        TFS_PID=$(pgrep -n -x tfs 2>/dev/null)
        if [ -n "$TFS_PID" ] && [ -e "/proc/$TFS_PID/oom_score_adj" ]; then
            break
        fi
        TFS_PID=""
        if ! kill -0 "$SERVER_PID" 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if [ -n "$TFS_PID" ]; then
        # -1000 = nunca matar este processo (máxima proteção)
        echo -900 > "/proc/$TFS_PID/oom_score_adj" 2>/dev/null
        echo "TFS (PID $TFS_PID) protegido contra OOM killer."
    else
        echo "Nao foi possivel localizar o PID do TFS para aplicar a protecao OOM."
    fi

    # Aguarda o servidor terminar
    wait $SERVER_PID
    EXIT_CODE=$?

    # Backup do banco após cada run
    MYSQL_USER=""
    MYSQL_PASS=""
    MYSQL_DATABASE=""
    # mysqldump -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DATABASE > backups/$(date '+%Y-%m-%d_%H-%M').sql

    if [ $EXIT_CODE -eq 0 ]; then
        echo "Servidor encerrou normalmente. Aguardando 5 segundos..."
        sleep 5
    else
        echo "Crash detectado! Reiniciando em 5 segundos..."
        sleep 5
    fi
done
