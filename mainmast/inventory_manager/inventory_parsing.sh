#!/usr/bin/env bash
# inventory_parsing.sh
# File che si occupa di parsare un inventario ansible like in formato ini.
# Fa uso delle funzioni di utilita' definite in inventory_manager/inventory_parsing_utilities.sh
# e delle funzioni di utilita' definite in lib/common.sh

source "$(dirname "${BASH_SOURCE[0]}")/inventory_parsing_utilities.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# host_list
# Funzione che estrae e ritorna la lista di host da un .ini inventory file
# 
host_list() {}

# add_host
# Funzione richiamata da inventory_read per aggiungere un host all'array degli host
# Riceve in input la stringa contenente l'host da aggiungere.
# La funzione viene richiamata per ogni host in un gruppo,
# e per ogni host in ogni gruppo presente in un gruppo di gruppi.
# La funzione non ritorna nulla, ma modifica l'array globale host_array.
add_host() {
	local line="$1"
	host_array+=("$line")
}

# add_group
# Funzione richiamata da inventory_read per aggiungere un gruppo all'array dei gruppi
# Riceve in input la stringa contenente il nome del gruppo da aggiungere.
# La funzione viene richiamata solo sia se il gruppo e' uno solo, sia per ogni gruppo
# all'interno di un gruppo di gruppi.
# La funzione non ritorna nulla, ma modifica l'array globale group_array.
add_group() {
	local group_name="$1"
	group_array+=("$group_name")
}

# inventory_read
# Funzione che legge riga per riga un .ini inventory file.
# Riceve in input il path del file inventory da leggere,
# e il gruppo o l'host target per cui fare il parsing.
#
# Esegue i controlli per ogni riga e richiama le funzioni di aggiunta host o gruppi.
# Richiamando solo le funzioni di aggiunta per righe valide, non ritorna nulla.
inventory_read() {
	declare -g -a host_array=()
	local inventory_file="$1"
	while IFS= read -r line || [[ -n "$line" ]]; do
		# trim della linea
		line=$(trim "$line")
		
		# salta linee vuote e commenti
		if is_line_empty "$line" || is_line_comment "$line"; then continue; fi
		
		# controlla se e' un gruppo
		if is_group "$line"; then
			if parent_group=$(get_parent_group "$line"); then
				# gestisci gruppo di gruppi
				continue
			else
				# gestisci gruppo normale
				continue
			fi
		fi
		
		# controlla se e' un host valido
		if is_valid_remote "$line"; then
			# gestisci host
			continue
		fi
		
		# altrimenti, linea non valida
		echo "Linea non valida nell'inventario: $line" >&2
	done < "$inventory_file"
}