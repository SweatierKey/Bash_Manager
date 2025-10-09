#!/usr/bin/env bash
# Controlla la validita' dell'inventario.

source "$(dirname "$0")/../lib/common.sh"

is_comment() {
    local line="$1"
    [[ "$line" =~ ^#.*$ ]] && return 0 || return 1
}

is_line_empty() {
    local line="$1"
    [[ -z "$line" ]] && return 0 || return 1
}

is_duplicate() {
    local ip="$1"
    local -n ip_array_ref=$2
    for existing_ip in "${ip_array_ref[@]}"; do
        if [[ "$existing_ip" == "$ip" ]]; then
            return 0
        fi
    done
    return 1
}

is_unique() {
    local ip="$1"
    local -n ip_array_ref=$2
    for existing_ip in "${ip_array_ref[@]}"; do
        if [[ "$existing_ip" == "$ip" ]]; then
            return 1
        fi
    done
    return 0
}

is_valid_ip() {
    local ip="$1"
    local IFS='.'
    local -a octets=($ip)
    
    # Controlla che ci siano esattamente 4 ottetti
    [[ ${#octets[@]} -eq 4 ]] || return 1
    
    for octet in "${octets[@]}"; do
        # Controlla che ogni ottetto sia un numero tra 0 e 255
        if ! [[ "$octet" =~ ^[0-9]+$ ]] || ((octet < 0 || octet > 255)); then
            #todo: loggare errore
            return 1
        fi
    done
    
    return 0
}

is_group() {
    local line="$1"
    [[ "$line" =~ ^\[[a-zA-Z0-9_-]+\]$ ]] && return 0 || return 1
}

get_group() {
    local line="$1"
    if [[ "$line" =~ ^\[([a-zA-Z0-9_-]+)\]$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    else
        return 1
    fi
}

is_children_group() {
    local line="$1"
    [[ "$line" =~ ^\[[a-zA-Z0-9_-]+:children\]$ ]] && return 0 || return 1
}

get_children_group() {
    local line="$1"
    if [[ "$line" =~ ^\[[a-zA-Z0-9_-]+:children\]$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    else
        return 1
    fi
}


is_valid_remote() {
    local line="$1"
    [[ "$line" =~ ^([a-zA-Z0-9_.-]+|([0-9]{1,3}\.){3}[0-9]{1,3})$ ]] && return 0 || return 1
}

is_hostname() {
    local line="$1"
    [[ "$line" =~ ^[a-zA-Z0-9_.-]+$ ]] && return 0 || return 1
}

# estrae un'array di host dall'inventory file in base al gruppo target
host_array() {
    local inventory_file="$1"
    local target_group="$2"
    local -a hosts=()
    local in_target_group=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # trim della linea
        line=$(trim "$line")
        
        # salta linee vuote e commenti
        if is_line_empty "$line" || is_comment "$line"; then
            continue
        fi
        
        # controlla se e' un gruppo
        if is_group "$line"; then
            current_group=$(get_group "$line")
            if [[ "$current_group" == "$target_group" ]]; then
                in_target_group=true
            else
                in_target_group=false
            fi
            continue
        fi
        
        # se siamo nel gruppo target, aggiungi l'host all'array
        if $in_target_group && is_valid_remote "$line"; then
            hosts+=("$line")
        fi
    done < "$inventory_file"
    
    echo "${hosts[@]}"
}

# crea un'array di gruppi figli per un dato gruppo padre
children_groups() {
    local inventory_file="$1"
    local parent_group="$2"
    local -a children=()
    local in_parent_group=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # trim della linea
        line=$(trim "$line")
        
        # salta linee vuote e commenti
        if is_line_empty "$line" || is_comment "$line"; then
            continue
        fi
        
        # controlla se e' un gruppo figli
        if is_children_group "$line"; then
            current_group=$(get_children_group "$line")
            if [[ "$current_group" == "$parent_group" ]]; then
                in_parent_group=true
            else
                in_parent_group=false
            fi
            continue
        fi
        
        # se siamo nel gruppo padre, aggiungi il gruppo figlio all'array
        if $in_parent_group && is_group "$line"; then
            child_group=$(get_group "$line")
            children+=("$child_group")
        fi
    done < "$inventory_file"
    
    echo "${children[@]}"
}

# controlla la validita' dell'inventory file e del gruppo target
check_inventory() {
    local inventory_file="$1"
    local target_group="$2"
    local -a all_ips=()
    local current_group=""
    local line_number=0
    
    # controlla che il file esista
    if [[ ! -f "$inventory_file" ]]; then
        echo "Errore: il file di inventario '$inventory_file' non esiste."
        return 1
    fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_number++))
        # trim della linea
        line=$(trim "$line")
        
        # salta linee vuote e commenti
        if is_line_empty "$line" || is_comment "$line"; then
            continue
        fi
        
        # controlla se e' un gruppo
        if is_group "$line"; then
            current_group=$(get_group "$line")
            if [[ -z "$current_group" ]]; then
                echo "Errore: nome gruppo non valido alla linea $line_number."
                return 1
            fi
            continue
        fi
        
        # controlla se e' un host valido
        if is_valid_remote "$line"; then
            if ! is_hostname "$line"; then
                # e' un indirizzo IP, controlla la validita'
                if ! is_valid_ip "$line"; then
                    echo "Errore: indirizzo IP non valido '$line' alla linea $line_number."
                    return 1
                fi
                
                if ! is_unique "$line" all_ips; then
                    echo "Errore: indirizzo IP duplicato '$line' alla linea $line_number."
                    return 1
                fi
            else
                # e' un hostname, controlla la duplicazionee
                if ! is_unique "$line" all_ips; then
                    echo "Errore: hostname duplicato '$line' alla linea $line_number."
                    return 1
                fi
            fi
            
            all_ips+=("$line")
        else
            echo "Errore: linea non valida '$line' alla linea $line_number."
            return 1
        fi
    done < "$inventory_file"
    
    # controlla che il gruppo target esista nell'inventario
    if [[ -n "$target_group" ]]; then
        if ! grep -q "^\[$target_group\]" "$inventory_file"; then
            echo "Errore: il gruppo target '$target_group' non esiste nell'inventario."
            return 1
        fi
    fi
    
    return 0
}