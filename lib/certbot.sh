#!/usr/bin/env bash

request_certificate() {
  if [[ "${CERT_METHOD}" == "cloudflare" ]]; then
    log "Requesting TLS certificate with Certbot (Cloudflare DNS challenge)..."
    
    # Validate that cloudflare credentials exist
    if [[ ! -f "${CLOUDFLARE_INI}" ]]; then
      die "Cloudflare credentials file not found at ${CLOUDFLARE_INI}. Cannot proceed with DNS challenge."
    fi
    
    run_cmd certbot certonly \
      --dns-cloudflare \
      --dns-cloudflare-credentials "${CLOUDFLARE_INI}" \
      --non-interactive \
      --agree-tos \
      --no-eff-email \
      --email "${CERTBOT_EMAIL}" \
      -d "${WEBSITE_NAME}" \
      -d "*.${WEBSITE_NAME}"
    success "TLS certificate obtained successfully (wildcard included)."
  elif [[ "${CERT_METHOD}" == "http" ]]; then
    log "Requesting TLS certificate with Certbot (HTTP challenge)..."
    
    # Ensure nginx is running for HTTP challenge
    if ! systemctl is-active --quiet nginx; then
      log "Starting nginx for HTTP challenge..."
      if ! run_cmd systemctl start nginx; then
        warn "Failed to start nginx. The HTTP challenge will likely fail without nginx running to serve the validation files."
      fi
    fi
    
    run_cmd certbot certonly \
      --nginx \
      --non-interactive \
      --agree-tos \
      --no-eff-email \
      --email "${CERTBOT_EMAIL}" \
      -d "${WEBSITE_NAME}"
    success "TLS certificate obtained successfully."
  else
    die "Invalid certificate method: ${CERT_METHOD}. Must be 'cloudflare' or 'http'."
  fi
}

ensure_certbot_renewal() {
  log "Ensuring Certbot automatic renewal is enabled..."

  local deploy_hook_dir="/etc/letsencrypt/renewal-hooks/deploy"
  local hook_path="${deploy_hook_dir}/reload-nginx.sh"

  run_cmd install -d -m 755 "${deploy_hook_dir}"
  cat > "${hook_path}" <<'EOF'
#!/usr/bin/env bash
set -e

if command -v systemctl >/dev/null 2>&1; then
  systemctl reload nginx || true
fi
EOF
  run_cmd chmod 755 "${hook_path}"
  success "Installed Certbot deploy hook to reload NGINX after renewals (${hook_path})."

  if systemctl list-unit-files | grep -q '^certbot.timer'; then
    if run_cmd systemctl enable --now certbot.timer; then
      success "certbot.timer enabled for automatic renewals."
    else
      warn "Failed to enable certbot.timer; renewals may not run automatically."
    fi
  else
    warn "certbot.timer not found; relying on the Certbot package's default renewal mechanism."
  fi
}
