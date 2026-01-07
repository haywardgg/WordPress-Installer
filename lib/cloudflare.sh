#!/usr/bin/env bash

configure_cloudflare_credentials() {
  log "Configuring Cloudflare DNS credentials..."
  run_cmd mkdir -p "${SECRETS_DIR}"
  run_cmd chmod 700 "${SECRETS_DIR}"

  if [[ -f "${CLOUDFLARE_INI}" ]]; then
    if [[ ${NON_INTERACTIVE} -eq 1 ]]; then
      if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
        log "Keeping existing Cloudflare credentials at ${CLOUDFLARE_INI}."
        return
      fi
      overwrite="y"
    else
      read -rp "Cloudflare credentials already exist at ${CLOUDFLARE_INI}. Overwrite? [y/N]: " overwrite
      if [[ ! "${overwrite,,}" =~ ^y$ ]]; then
        log "Keeping existing Cloudflare credentials."
        return
      fi
    fi
  fi

  if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    if [[ ${NON_INTERACTIVE} -eq 1 ]]; then
      die "--non-interactive is set; provide CLOUDFLARE_API_TOKEN or ensure ${CLOUDFLARE_INI} exists."
    fi

    read -rp "Enter your Cloudflare API Token (Zone DNS edit permissions): " CLOUDFLARE_API_TOKEN
  fi

  CLOUDFLARE_API_TOKEN=$(trim "${CLOUDFLARE_API_TOKEN}")

  [[ -n "${CLOUDFLARE_API_TOKEN}" ]] || die "Cloudflare API token cannot be empty."

  if [[ "${CLOUDFLARE_API_TOKEN}" =~ ^[A-Fa-f0-9]{37}$ ]]; then
    die "Detected a Cloudflare Global API Key. This script requires an API Token with Zone:DNS Edit permissions instead."
  fi

  if [[ "${CLOUDFLARE_API_TOKEN}" =~ [^A-Za-z0-9_-] ]]; then
    die "Cloudflare API token contains invalid characters (only letters, numbers, _ and - are allowed)."
  fi

  if [[ ${#CLOUDFLARE_API_TOKEN} -lt 20 ]]; then
    die "Cloudflare API token looks too short. Please paste the full token without quotes or extra characters."
  fi

  cat > "${CLOUDFLARE_INI}" <<EOF
dns_cloudflare_api_token = ${CLOUDFLARE_API_TOKEN}
EOF

  run_cmd chmod 600 "${CLOUDFLARE_INI}"
  success "Saved Cloudflare credentials to ${CLOUDFLARE_INI}."
}
