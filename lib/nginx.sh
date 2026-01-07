#!/usr/bin/env bash

configure_nginx() {
  local php_version="$1"
  local php_fpm_socket="/run/php/php${php_version}-fpm.sock"
  local site_config="${AVAILABLE_SITES_DIR}/${WEBSITE_NAME}"
  local template="${TEMPLATES_DIR}/nginx-site.conf.tpl"

  WEBSITE_NAME="${WEBSITE_NAME}" DOCUMENT_ROOT="${DOCUMENT_ROOT}" PHP_VERSION="${php_version}" PHP_FPM_SOCKET="${php_fpm_socket}" \
    envsubst '${WEBSITE_NAME} ${DOCUMENT_ROOT} ${PHP_VERSION} ${PHP_FPM_SOCKET}' < "${template}" > "${site_config}"

  run_cmd ln -sf "${site_config}" "${ENABLED_SITES_DIR}/${WEBSITE_NAME}"
  log "NGINX configuration written for ${WEBSITE_NAME}."
}
