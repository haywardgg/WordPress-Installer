#!/usr/bin/env bash

load_stored_root_password() {
  if [[ ! -f "${MARIADB_ROOT_PASS_FILE}" ]]; then
    return 1
  fi

  local stored_password
  stored_password=$(<"${MARIADB_ROOT_PASS_FILE}")
  stored_password=$(trim "${stored_password}")

  if [[ -z "${stored_password}" ]]; then
    warn "Stored MariaDB root password file ${MARIADB_ROOT_PASS_FILE} is empty."
    return 1
  fi

  local stored_cmd=(mysql -u root -p"${stored_password}")

  if ! "${stored_cmd[@]}" -e "SELECT 1" >/dev/null 2>&1; then
    warn "Stored MariaDB root password at ${MARIADB_ROOT_PASS_FILE} is invalid."
    return 1
  fi

  MYSQL_ROOT_PASSWORD="${stored_password}"
  MYSQL_ROOT_CMD=("${stored_cmd[@]}")

  return 0
}

store_root_password() {
  local password="$1"

  if [[ -z "${password}" ]]; then
    return
  fi

  run_cmd mkdir -p "${SECRETS_DIR}"
  run_cmd chmod 700 "${SECRETS_DIR}"

  printf '%s\n' "${password}" >"${MARIADB_ROOT_PASS_FILE}"
  run_cmd chmod 600 "${MARIADB_ROOT_PASS_FILE}"
  log "Saved MariaDB root password to ${MARIADB_ROOT_PASS_FILE}."
}

secure_mariadb() {
  log "Securing MariaDB installation..."
  run_cmd systemctl enable --now mariadb

  MYSQL_ROOT_CMD=(mysql --protocol=socket -u root)

  if "${MYSQL_ROOT_CMD[@]}" -e "SELECT 1" >/dev/null 2>&1; then
    if [[ ${REUSE_EXISTING_STACK} -eq 1 ]]; then
      log "Using existing MariaDB root account via socket authentication."
      ROOT_PASSWORD_STATUS="socket-auth"
      return
    fi

    MYSQL_ROOT_PASSWORD=$(generate_password)
    "${MYSQL_ROOT_CMD[@]}" <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL
    MYSQL_ROOT_CMD=(mysql -u root -p"${MYSQL_ROOT_PASSWORD}")
    CREATED_ROOT_USER=1
    ROOT_PASSWORD_STATUS="created"
    log "MariaDB root password set."
    store_root_password "${MYSQL_ROOT_PASSWORD}"
    return
  fi

  if load_stored_root_password; then
    ROOT_PASSWORD_STATUS="stored-file"
    log "Using MariaDB root password from ${MARIADB_ROOT_PASS_FILE}."
    return
  fi

  if [[ ${REUSE_EXISTING_STACK} -eq 1 ]]; then
    if [[ -z "${EXISTING_ROOT_PASSWORD:-}" ]]; then
      if [[ ${NON_INTERACTIVE} -eq 1 ]]; then
        die "--non-interactive is set; provide EXISTING_ROOT_PASSWORD or ensure ${MARIADB_ROOT_PASS_FILE} exists with a valid password."
      fi

      read -rp "Enter existing MySQL root password: " EXISTING_ROOT_PASSWORD
    fi

    EXISTING_ROOT_PASSWORD=$(trim "${EXISTING_ROOT_PASSWORD}")
    MYSQL_ROOT_CMD=(mysql -u root -p"${EXISTING_ROOT_PASSWORD}")

    if ! "${MYSQL_ROOT_CMD[@]}" -e "SELECT 1" >/dev/null 2>&1; then
      die "Unable to authenticate to existing MariaDB root user."
    fi

    MYSQL_ROOT_PASSWORD="${EXISTING_ROOT_PASSWORD}"
    store_root_password "${EXISTING_ROOT_PASSWORD}"
    ROOT_PASSWORD_STATUS="provided-existing"
    log "Using provided MariaDB root password for database setup."
    return
  fi

  if [[ ${NON_INTERACTIVE} -eq 0 ]]; then
    read -rp "Enter existing MySQL root password (leave blank if none): " EXISTING_ROOT_PASSWORD
  fi

  EXISTING_ROOT_PASSWORD=$(trim "${EXISTING_ROOT_PASSWORD:-}")

  if [[ -n "${EXISTING_ROOT_PASSWORD}" ]]; then
    MYSQL_ROOT_CMD=(mysql -u root -p"${EXISTING_ROOT_PASSWORD}")
    MYSQL_ROOT_PASSWORD="${EXISTING_ROOT_PASSWORD}"
    ROOT_PASSWORD_STATUS="provided-existing"
  else
    MYSQL_ROOT_CMD=(mysql -u root)
  fi

  if ! "${MYSQL_ROOT_CMD[@]}" -e "SELECT 1" >/dev/null 2>&1; then
    die "Unable to authenticate to MariaDB as root. Aborting."
  fi

  if [[ -n "${EXISTING_ROOT_PASSWORD}" ]]; then
    log "Using existing MariaDB root password without changing it."
    store_root_password "${EXISTING_ROOT_PASSWORD}"
    return
  fi

  MYSQL_ROOT_PASSWORD=$(generate_password)
  "${MYSQL_ROOT_CMD[@]}" <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL
  MYSQL_ROOT_CMD=(mysql -u root -p"${MYSQL_ROOT_PASSWORD}")
  CREATED_ROOT_USER=1
  ROOT_PASSWORD_STATUS="created"
  log "MariaDB root password set."
  store_root_password "${MYSQL_ROOT_PASSWORD}"
}

create_database() {
  DB_PASSWORD=${DB_PASSWORD:-$(generate_password)}
  "${MYSQL_ROOT_CMD[@]}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
  log "Database ${DB_NAME} and user ${DB_USER} created."
}
