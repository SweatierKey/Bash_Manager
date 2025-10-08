#!/bin/bash

# =============================================================================
# BASH ORCHESTRATOR - Common Utilities
# =============================================================================

# Configurazione globale
readonly SCRIPT_DIR="$(cd ""){dirname "${BASH_SOURCE[0]}"} && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Colori per output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Simboli per output
readonly CHECK_MARK="✓"
readonly CROSS_MARK="✗"
readonly WARNING_MARK="⚠"
readonly INFO_MARK="ℹ"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_level_to_number() {
    case "$1" in
        DEBUG) echo 0 ;; 
        INFO)  echo 1 ;; 
        WARN)  echo 2 ;; 
        ERROR) echo 3 ;; 
        *) echo 1 ;; 
    esac
}

should_log() {
    local level="$1"
    local current_level_num=$(log_level_to_number "$LOG_LEVEL")
    local message_level_num=$(log_level_to_number "$level")
    
    [ "$message_level_num" -ge "$current_level_num" ]
}

log() {
    local level="$1"
    local message="$2"
    local color=""
    local symbol=""
    
    should_log "$level" || return 0
    
    case "$level" in
        DEBUG)
            color="$CYAN"
            symbol="🔍"
            ;; 
        INFO)
            color="$BLUE"
            symbol="$INFO_MARK"
            ;; 
        WARN)
            color="$YELLOW"
            symbol="$WARNING_MARK"
            ;; 
        ERROR)
            color="$RED"
            symbol="$CROSS_MARK"
            ;;
    esac
    
    printf "${color}[%s] %s %s${NC}\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$symbol" \
        "$message" >&2
}

log_debug() { log "DEBUG" "$1"; }
log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }

log_success() {
    printf "${GREEN}[%s] %s %s${NC}\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$CHECK_MARK" \
        "$1" >&2
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Verifica se un comando esiste
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verifica se una variabile è definita e non vuota
is_set() {
    [[ -n "
${!1:-}" ]]
}

# Trim whitespace da una stringa
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace
    printf '%s' "$var"
}

# Valida formato IP
is_valid_ip() {
    local ip="$1"
    local IFS='.'
    local -a octets=($ip)
    
    [[ ${#octets[@]} -eq 4 ]] || return 1
    
    for octet in "${octets[@]}"; do
        [[ $octet =~ ^[0-9]+$ ]] || return 1
        [[ $octet -ge 0 && $octet -le 255 ]] || return 1
    done
    
    return 0
}

# Valida formato hostname/FQDN
is_valid_hostname() {
    local hostname="$1"
    [[ $hostname =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]
}

# Escape speciali caratteri per uso in regex
escape_regex() {
    printf '%s\n' "$1" | sed 's/[[\.*^$()+?{|]/\\&/g'
}

# Genera timestamp per file temporanei
generate_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

# Cleanup function per file temporanei
declare -a TEMP_FILES=()
cleanup_temp_files() {
    for file in "${TEMP_FILES[@]}"; do
        [[ -f "$file" ]] && rm -f "$file"
    done
}

# Registra file temporaneo per cleanup automatico
register_temp_file() {
    TEMP_FILES+=("$1")
}

# Trap per cleanup automatico
trap cleanup_temp_files EXIT

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Valida che tutti i parametri richiesti siano forniti
validate_required_params() {
    local -a missing=()
    
    while [[ $# -gt 0 ]]; do
        local param_name="$1"
        if ! is_set "$param_name"; then
            missing+=("$param_name")
        fi
        shift
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Parametri richiesti mancanti: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Valida che un file esista e sia leggibile
validate_file_readable() {
    local file="$1"
    local description="${2:-File}"
    
    if [[ ! -f "$file" ]]; then
        log_error "$description non trovato: $file"
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        log_error "$description non leggibile: $file"
        return 1
    fi
    
    return 0
}

# Valida che una directory esista e sia accessibile
validate_directory() {
    local dir="$1"
    local description="${2:-Directory}"
    
    if [[ ! -d "$dir" ]]; then
        log_error "$description non trovata: $dir"
        return 1
    fi
    
    if [[ ! -r "$dir" ]]; then
        log_error "$description non accessibile: $dir"
        return 1
    fi
    
    return 0
}