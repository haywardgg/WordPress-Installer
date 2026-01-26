#!/usr/bin/env bash

install_dependencies() {
  local packages=(
    nginx
    certbot
    python3-certbot-nginx
    php-fpm php-common php-mysql php-xml php-gd php-curl php-json
    mariadb-client mariadb-server
    curl wget unzip rsync openssl gettext-base
  )
  
  # Add Cloudflare DNS plugin if using cloudflare method
  if [[ "${CERT_METHOD}" == "cloudflare" ]]; then
    packages+=(python3-certbot-dns-cloudflare)
    log "Installing packages including Cloudflare DNS plugin..."
  else
    log "Installing packages with standard certbot (no Cloudflare plugin)..."
  fi

  run_cmd apt-get update -y
  run_cmd apt-get install -y "${packages[@]}"
  success "Package installation complete."
}
