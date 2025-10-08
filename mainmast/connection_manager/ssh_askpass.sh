#!/usr/bin/env bash

# Legge la password in modo sicuro e la restituisce
read_passwd() {
  read -s -p "Password: " PASSWORD
  echo
  echo "$PASSWORD"
}

# Imposta le variabili d’ambiente SSH_ASKPASS per leggere da FD 3
setup_env() {
  local pass="$1"
  exec 3<<<"$pass"
  export SSH_ASKPASS='bash -c "cat <&3"'
  export SSH_ASKPASS_REQUIRE=force
}

# Esegue il comando passato come argomento, mantenendo FD 3 aperto
run_askpass_cmd() {
  if [[ $# -eq 0 ]]; then
    echo "Error: no command specified" >&2
    return 1
  fi
  "$@"
  exec 3<&-
}

# Funzione wrapper completa, generica per qualunque comando SSH_ASKPASS-compatibile
ssh_askpass() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: ssh_askpass <command> [args...]" >&2
    return 1
  fi

  local password
  password=$(read_passwd)
  setup_env "$password"
  run_askpass_cmd "$@"
}

