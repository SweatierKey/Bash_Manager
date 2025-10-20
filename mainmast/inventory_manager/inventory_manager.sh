#!/usr/bin/env bash
# Controlla la validita' dell'inventario.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

get_group() {
	local line="$1"
	if [[ "$line" =~ ^\[([a-zA-Z0-9_-]+)\]$ ]]; then
		echo "${BASH_REMATCH[1]}"
		return 0
	else
		return 1
	fi
}

get_nested_group() {
	local line="$1"
	if [[ "$line" =~ ^([a-zA-Z0-9_-]+)$ ]]; then
		echo "${BASH_REMATCH[1]}"
		return 0
	else
		return 1
	fi
}

get_parent_group() {
	local line="$1"
	if [[ "$line" =~ ^\[([a-zA-Z0-9_-]+):children\]$ ]]; then
		echo "${BASH_REMATCH[1]}"
		return 0
	else
		return 1
	fi
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
		if is_line_empty "$line" || is_line_comment "$line"; then continue; fi
		
		# controlla se e' un gruppo
		if is_group "$line"; then
			current_group=$(get_group "$line")
			in_target_group=$([[ "$current_group" == "$target_group" ]] && echo true || echo false)
			continue
		fi
		
		# se siamo nel gruppo target, aggiungi l'host all'array
		if $in_target_group && is_valid_remote "$line"; then
			hosts+=("$line")
		fi
	done < "$inventory_file"
	
	printf "%s\n" "${hosts[@]}"
}

# crea un'array di gruppi figli per un dato gruppo padre
# quindi restituisce i gruppi figli di un gruppo padre
# solo se il gruppo target e' un gruppo padre
children_groups_array() {
	local inventory_file="$1"
	local parent_group=""
	local target_group="$2"
	local -a children=()
	local in_parent_group=false
	
	while IFS= read -r line || [[ -n "$line" ]]; do
		# trim della linea
		line=$(trim "$line")
		
		# salta linee vuote e commenti
		if is_line_empty "$line" || is_line_comment "$line"; then continue; fi
		
		# controlla se e' un gruppo padre
		if is_parent_group "$line"; then
			parent_group=$(get_parent_group "$line")
			in_parent_group=$([[ "$target_group" == "$parent_group" ]] && echo true || echo false)
			continue
		fi
		
		# Se trovi una nuova sezione di definizione gruppo, esci dalla sezione figli
		if (is_group "$line" || is_parent_group "$line") && $in_parent_group; then
			in_parent_group=false
			continue
		fi
		
		
		# Se siamo nella sezione figli, aggiungi il gruppo
		if $in_parent_group && is_nested_group "$line"; then
			child_group=$(get_nested_group "$line")
			children+=("$child_group")
		fi
	done < "$inventory_file"
	
	printf "%s\n" "${children[@]}"
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
		if is_line_empty "$line" || is_line_comment "$line"; then
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
