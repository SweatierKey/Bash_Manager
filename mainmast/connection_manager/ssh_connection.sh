#!/usr/bin/env bash
# Si occupa di gestire la connessione ssh.

source "$(dirname "$0")/../inventory_manager/inventory_manager.sh"

# funzione che testa la raggiungibilita' di un host
is_reachable() {
    local host="$1"
    local port="${2:-22}"
    ( echo >/dev/tcp/"$host"/"$port" ) >/dev/null 2>&1
    return $?
}

# funzione che effettua la connessione ssh
connection() {
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@"
}

# funzione che effettua la connessione ssh sulla lista degli host estratta dall'inventario
# esegue il payload sui target.
connect() {
    local hosts
    readarray -t hosts < <(host_array "$inventory_file" "$target_group")

    for host in "$hosts[@]"; do
        if is_reachable "$host"; then
            echo "Connessione a $host riuscita"
            connection "$host"
        else
            echo "Connessione a $host fallita"
        fi
    done
}