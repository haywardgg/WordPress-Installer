#!/usr/bin/env bash

set_permissions() {
  run_cmd chown -R "${NGINX_USER}:${NGINX_GROUP}" "${DOCUMENT_ROOT}"
  run_cmd find "${DOCUMENT_ROOT}" -type d -exec chmod 755 {} \;
  run_cmd find "${DOCUMENT_ROOT}" -type f -exec chmod 644 {} \;
  run_cmd chmod -R 775 "${DOCUMENT_ROOT}/wp-content" "${DOCUMENT_ROOT}/wp-content/themes" "${DOCUMENT_ROOT}/wp-content/plugins"
  success "Permissions updated for ${DOCUMENT_ROOT}."
}
