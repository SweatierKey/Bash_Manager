#!/usr/bin/env bash
# File che contiene le utilities di per parsare il file inventory.
# Lista con micro descrizione delle funzioni che questo file mette a disposizione:
# is_line_comment - controlla se la riga passata in input e' un commento. True se e' un commento.
# is_line_empty - controlla se la riga passata in input' e' vuota. True se e' vuota
# is_duplicate - controlla se la riga passata in input e' duplicata, \
#comparandola con un array passato come secondo argument. True se e' duplicata
# is_unique - controlla se la riga passata in input e' unica, \
#comparandola con un array passato come secondo argument. True se e' unica
# is_valid_ip - controlla la validita' di un ip passato in input. True se e' valido
# is_group - controlla se la riga passata in input e' un gruppo. True se e' un gruppo.
# is_nested_group - controlla se la riga passata in input e' un gruppo normale. True se lo e'.
# is_parent_group - controlla se la riga passata in input e' un gruppo di gruppi. True se lo e'.
# is_valid_remote - controlla se la riga passata in input e' un remote valido sintatticamente. True se lo e'.
# is_hostname - controla se la riga passata in input e' un hostname. True se lo e'.

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# is_line_comment
# Funzione che controlla se una riga e' un commento.
# Riceve solo un valore in input,
# il valore deve essere una stringa.
# 
# Ritorna 0 se la linea e' un commento
# Ritorna 1 se la rica non e' un commento
is_line_comment() {
	local line="$1"
	if [[ "$line" =~ ^#.*$ ]]; then
		return 0
	else
		return 1
	fi
}

# is_line_empty
# Funzione che controlla se una linea e' vuota.
# Rivece in input la stringa da controllare.
#
# Ritorna 0 se e' vuota.
# Ritorna 1 se non e' vuota.
is_line_empty() {
	local line="$1"
	if [[ -z "$line" ]]; then
		return 0
	else
		return 1
	fi
}

# is_duplicate
# Funzione che verifica se una riga e' duplicata.
# Riceve come primo argument la stringa da controllare,
# come secondo un array intero sul quale fa la verifica di duplicita'.
#
# Ritorna 0 se la linea e' presente nell'array.
# Ritorna 1 se la linea non e' presente nell'array.
is_duplicate() {
	local line="$1"
	local -n ip_array_ref=$2
	for existing_ip in "${ip_array_ref[@]}"; do
		if [[ "$existing_ip" == "$line" ]]; then
			return 0
		fi
	done
	return 1
}

# is_unique
# Funzione che verifica se una stringa e' unica.
# Riceve come primo argument una stringa contenente la riga da controllare,
# come seconda un'intero array sul quale verifica l'unicita' della stringa ricevuta.
#
# Ritorna 0 se la stringa e' unica.
# Ritorna 1 se la stringa non e' unica.
is_unique() {
	local line="$1"
	local -n ip_array_ref=$2
	for existing_ip in "${ip_array_ref[@]}"; do
		if [[ "$existing_ip" == "$line" ]]; then
			return 1
		fi
	done
	return 0
}

# is_valid_ip
# Funzione che verifica la validita' di un ip.
# Riceve in input una stringa contenente l'ottetto di ip da verificare.
# Divide la stringa per "."
# Verifica con regex che ogni ottetto sia un numero e sia compreso tra 0 e 255.
#
# Ritorna 0 se la stringa e' un ip valido.
# Ritorna 1 se la stringa non e' un ip valido.
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

# is_group
# Funzione che controlla se una stringa e' un gruppo,
# quindi se e' un gruppo normale, contenente host ip o hostname.
# Verifica con regex se e' un gruppo normale.
#
# Ritorna 0 se e' un gruppo.
# Ritorna 1 se non e' un gruppo.
is_group() {
	local line="$1"
	if [[ "$line" =~ ^\[[a-zA-Z0-9_-]+\]$ ]]; then
		return 0
	else
		return 1
	fi
}

# is_nested_group
# Funzione che controlla se una stringa e' un gruppo,
# quindi se e' un gruppo normale, contenente host ip o hostname.
# Verifica con regex se e' un gruppo normale.
#
# Ritorna 0 se e' un gruppo.
# Ritorna 1 se non e' un gruppo.
is_nested_group() {
	local line="$1"
	if [[ "$line" =~ ^([a-zA-Z0-9_-]+)$ ]]; then
		return 0
	else
		return 1
	fi
}

# is_parent_group
# Funzione che controlla se una stringa e' un gruppo di gruppi.
# Verifica con regex se e' un gruppo di gruppi cercando dopo il nome del gruppo
# il pattern ":children".
#
# Ritorna 0 se e' un gruppo di gruppi.
# Ritorna 1 se non e' un gruppo di gruppi.
is_parent_group() {
	local line="$1"
	if [[ "$line" =~ ^\[([a-zA-Z0-9_-]+):children\]$ ]]; then
		return 0
	else
		return 1
	fi
}

# is_valid_remote
# Funzione che controlla se una riga e' un remote valido sintatticamente.
# Riceve in input una stringa contenente la riga da controllare.
# Verifica con regex se e' un remote valido.
#
# Ritorna 0 se e' un remote valido.
# Ritorna 1 se non e' un remote valido.
is_valid_remote() {
	local line="$1"
	if [[ "$line" =~ ^([a-zA-Z0-9_.-]+|([0-9]{1,3}\.){3}[0-9]{1,3})$ ]]; then
		return 0
	else
		return 1
	fi
}

# is_hostname
# Funzione che controlla se una riga e' un hostname.
# Riceve in input una stringa contenente la riga da controllare.
# Verifica con regex se e' un hostname valido.
#
# Ritorna 0 se e' un hostname valido.
# Ritorna 1 se non e' un hostname valido.
is_hostname() {
	local line="$1"
	if [[ "$line" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
		return 0
	else
		return 1
	fi
}