#!/usr/bin/env bash

perform_dangerous_cleanup() {
  echo
  warn "DANGEROUS MODE ENABLED. THIS WILL DESTROY YOUR STACK." \
    "No backups will be created and the operation cannot be undone."

  cat <<WARNING
====================================================================
The --dangerous flag will:
  - Stop and purge all MariaDB packages and remove their data.
  - Stop and purge all Nginx packages.
  - Delete the entire ${DOCUMENT_ROOT_BASE} directory.

This is NOT recommended for production servers. Proceed only if you
are certain you want to wipe the existing installation. Use at your
own risk.
====================================================================
WARNING

  local confirmation

  if [[ ${NON_INTERACTIVE} -eq 1 ]]; then
    confirmation="${DANGEROUS_CONFIRM:-}"

    if [[ -z "${confirmation}" ]]; then
      die "--dangerous requires DANGEROUS_CONFIRM=PURGE in non-interactive mode."
    fi
  else
    read -rp "Type 'PURGE' to proceed with the destructive cleanup: " confirmation
  fi

  if [[ "${confirmation}" != "PURGE" ]]; then
    die "Dangerous cleanup aborted."
  fi

  warn "Proceeding with irreversible purge of MariaDB, Nginx, and ${DOCUMENT_ROOT_BASE}."

  log "Stopping services (ignoring errors if already absent)..."
  run_cmd systemctl stop mariadb || true
  run_cmd systemctl stop nginx || true

  log "Purging MariaDB packages and data..."
  if ! with_raw_output env DEBIAN_FRONTEND=noninteractive apt-get purge -y \
    mariadb-server mariadb-client mariadb-common mariadb-server-core mariadb-client-core; then
    warn "Unable to purge one or more MariaDB packages; continuing anyway."
  fi
  if ! run_cmd rm -rf /var/lib/mysql /etc/mysql; then
    warn "Unable to remove MariaDB data directories; continuing anyway."
  fi

  log "Purging Nginx packages..."
  if ! with_raw_output env DEBIAN_FRONTEND=noninteractive apt-get purge -y nginx nginx-common nginx-full; then
    warn "Unable to purge one or more Nginx packages; continuing anyway."
  fi

  log "Removing document root at ${DOCUMENT_ROOT_BASE}..."
  if ! run_cmd rm -rf "${DOCUMENT_ROOT_BASE}"; then
    warn "Unable to remove ${DOCUMENT_ROOT_BASE}; continuing anyway."
  fi

  log "Cleaning up unused packages and cache..."
  run_cmd apt-get autoremove -y || true
  run_cmd apt-get autoclean -y || true

  log "Removing stored secrets..."
  if ! run_cmd rm -f "${MARIADB_ROOT_PASS_FILE}"; then
    warn "Unable to remove stored MariaDB root password at ${MARIADB_ROOT_PASS_FILE}; continuing anyway."
  fi

  success "Dangerous cleanup complete. Proceeding with installation on a clean slate."
  echo
}
