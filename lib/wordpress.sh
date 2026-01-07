#!/usr/bin/env bash

prepare_document_root() {
  if [[ -d "${DOCUMENT_ROOT}" && "$(ls -A "${DOCUMENT_ROOT}" 2>/dev/null)" ]]; then
    die "The document root ${DOCUMENT_ROOT} is not empty. Please provide an empty directory."
  fi

  run_cmd install -d -m 755 "${DOCUMENT_ROOT}"
}

install_wordpress() {
  log "Downloading and configuring WordPress..."
  local tmp_dir
  tmp_dir=$(mktemp -d)

  run_cmd wget -q -O "${tmp_dir}/wordpress.tar.gz" https://wordpress.org/latest.tar.gz
  run_cmd tar xzf "${tmp_dir}/wordpress.tar.gz" -C "${tmp_dir}"
  run_cmd rsync -a "${tmp_dir}/wordpress/" "${DOCUMENT_ROOT}/"

  run_cmd cp "${DOCUMENT_ROOT}/wp-config-sample.php" "${DOCUMENT_ROOT}/wp-config.php"
  run_cmd rm -rf "${tmp_dir}"
}

configure_wp_config() {
  log "Updating wp-config.php with database credentials and salts..."
  python3 - <<PY
from pathlib import Path
import re
import urllib.request

config_path = Path("${DOCUMENT_ROOT}/wp-config.php")
contents = config_path.read_text()

contents = contents.replace("database_name_here", "${DB_NAME}")
contents = contents.replace("username_here", "${DB_USER}")
contents = contents.replace("password_here", "${DB_PASSWORD}")

salts = urllib.request.urlopen("https://api.wordpress.org/secret-key/1.1/salt/").read().decode()
contents = re.sub(
    r"(?ms)define\\(\s*'AUTH_KEY'.+?define\\(\s*'NONCE_SALT'.+?;\\n",
    salts,
    contents,
    count=1,
)

config_path.write_text(contents)
PY
}
