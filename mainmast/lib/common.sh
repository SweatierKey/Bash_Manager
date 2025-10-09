#!/usr/bin/env bash
# Funzioni comuni che aiutano gli altri script.

# astrazione del concetto di trimming degli spazi ad inizio e fine riga/stringa
trim() {
    local var="$*"
    # rimuove spazi iniziali
    var="${var#"${var%%[![:space:]]*}"}"
    # rimuove spazi finali
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}