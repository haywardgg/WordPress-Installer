#!/usr/bin/env bash

detect_existing_stack() {
  local mariadb_active=0

  if systemctl list-units --type=service --all | grep -qE '^mariadb\.service'; then
    if systemctl is-active --quiet mariadb; then
      mariadb_active=1
    fi
  fi

  if [[ ${mariadb_active} -eq 1 && -d "${DOCUMENT_ROOT_BASE}" ]]; then
    REUSE_EXISTING_STACK=1
    log "Existing MariaDB and web root detected. Assuming an additional WordPress site installation."
  fi
}
