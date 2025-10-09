#!/usr/bin/env bash
# Si occupa di gestire la connessione ssh.

source "$(dirname "$0")/../inventory_manager/inventory_manager.sh"

# funzione che testa la raggiungibilita' di un host
reachable() {
    ( echo >/dev/tcp/zero/22 ) >/dev/null 2>&1
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
    hosts=$(host_array)

    for host in "$hosts[@]"; do
        if reachable "$host"; then
            echo "Connessione a $host riuscita"
            connection "$host"
        else
            echo "Connessione a $host fallita"
        fi
    done
}