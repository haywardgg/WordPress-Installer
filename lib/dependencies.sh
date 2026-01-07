#!/usr/bin/env bash

install_dependencies() {
  local packages=(
    nginx
    python3-certbot-dns-cloudflare
    php-fpm php-common php-mysql php-xml php-gd php-curl php-json
    mariadb-client mariadb-server
    curl wget unzip rsync openssl gettext-base
  )

  log "Installing required packages..."
  run_cmd apt-get update -y
  run_cmd apt-get install -y "${packages[@]}"
  success "Package installation complete."
}
