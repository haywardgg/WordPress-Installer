#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/lib/globals.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/prompts.sh"
source "${SCRIPT_DIR}/lib/detect.sh"
source "${SCRIPT_DIR}/lib/dependencies.sh"
source "${SCRIPT_DIR}/lib/dangerous.sh"
source "${SCRIPT_DIR}/lib/cloudflare.sh"
source "${SCRIPT_DIR}/lib/mariadb.sh"
source "${SCRIPT_DIR}/lib/php.sh"
source "${SCRIPT_DIR}/lib/wordpress.sh"
source "${SCRIPT_DIR}/lib/certbot.sh"
source "${SCRIPT_DIR}/lib/nginx.sh"
source "${SCRIPT_DIR}/lib/permissions.sh"
source "${SCRIPT_DIR}/lib/services.sh"

trap on_exit EXIT

main() {
  parse_args "$@"
  require_root
  if [[ ${DANGEROUS_MODE} -eq 1 ]]; then
    perform_dangerous_cleanup
  fi
  detect_existing_stack
  prompt_inputs
  install_dependencies
  configure_cloudflare_credentials
  secure_mariadb
  configure_php
  prepare_document_root
  request_certificate
  ensure_certbot_renewal
  install_wordpress
  create_database
  configure_wp_config
  set_permissions
  configure_nginx "${PHP_VERSION}"
  reload_services

  local root_summary="unchanged (socket authentication)"
  case "${ROOT_PASSWORD_STATUS}" in
    created)
      root_summary="stored at ${MARIADB_ROOT_PASS_FILE}"
      ;;
    stored-file)
      root_summary="stored at ${MARIADB_ROOT_PASS_FILE}"
      ;;
    provided-existing)
      root_summary="unchanged (existing password provided)"
      ;;
    socket-auth)
      root_summary="unchanged (socket authentication)"
      ;;
    *)
      root_summary="unchanged (not modified)"
      ;;
  esac

  local root_display="${root_summary}"

  if [[ ${HIDE_SECRETS} -eq 1 ]]; then
    if [[ ${ROOT_PASSWORD_STATUS} == "created" || ${ROOT_PASSWORD_STATUS} == "provided-existing" ]]; then
      root_display="[hidden]"
    fi
  fi

  local db_password_display
  db_password_display=$(mask_secret "${DB_PASSWORD}")

  echo
  echo "==============================================="
  echo "Setup complete!"
  echo "Domain:           ${WEBSITE_NAME}"
  echo "Document root:    ${DOCUMENT_ROOT}"
  echo "Database name:    ${DB_NAME}"
  echo "Database user:    ${DB_USER}"
  echo "Database pass:    ${db_password_display}"
  echo "MySQL root pass:  ${root_display}"
  if [[ "${CERT_METHOD}" == "cloudflare" ]]; then
    echo "Cloudflare token: stored at ${CLOUDFLARE_INI}"
  fi
  echo "SSL method:       ${CERT_METHOD}"
  echo "==============================================="
}

main "$@"
