#!/usr/bin/env bash

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --verbose          Show full command output.
  --quiet            Hide most command output (default behavior).
  --hide-secrets     Mask sensitive values in the final summary.
  --no-colour        Disable coloured output.
  --non-interactive  Require environment variables for inputs.
  --dangerous        Purge MariaDB, Nginx, and /var/www/html after confirmation (irreversible).
  -h, --help         Show this help message.
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verbose)
        RAW_OUTPUT=1
        ;;
      --quiet)
        RAW_OUTPUT=0
        ;;
      --hide-secrets)
        HIDE_SECRETS=1
        ;;
      --no-colour)
        NO_COLOUR=1
        disable_colours
        ;;
      --non-interactive)
        NON_INTERACTIVE=1
        ;;
      --dangerous)
        DANGEROUS_MODE=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

prompt_inputs() {
  if [[ ${NON_INTERACTIVE} -eq 1 ]]; then
    local required_vars=(WEBSITE_NAME CERTBOT_EMAIL DB_NAME DB_USER DB_PASSWORD)

    for var in "${required_vars[@]}"; do
      local value
      value=$(trim "${!var:-}")

      if [[ -z "${value}" ]]; then
        die "--non-interactive is set; please provide ${var} via environment variable."
      fi

      printf -v "${var}" '%s' "${value}"
    done

    DOCUMENT_ROOT="${DOCUMENT_ROOT_BASE}/${WEBSITE_NAME}"
    return
  fi

  if [[ -z "${WEBSITE_NAME:-}" ]]; then
    read -rp "Enter your domain (e.g. example.com): " WEBSITE_NAME
  fi
  WEBSITE_NAME=$(trim "${WEBSITE_NAME:-}")
  [[ -n "${WEBSITE_NAME}" ]] || die "Domain name cannot be empty."

  if [[ -z "${CERTBOT_EMAIL:-}" ]]; then
    read -rp "Enter email for Let's Encrypt notifications: " CERTBOT_EMAIL
  fi
  CERTBOT_EMAIL=$(trim "${CERTBOT_EMAIL:-}")
  [[ -n "${CERTBOT_EMAIL}" ]] || die "Email is required for certificate issuance."

  DOCUMENT_ROOT="${DOCUMENT_ROOT_BASE}/${WEBSITE_NAME}"

  if [[ -z "${DB_NAME:-}" ]]; then
    read -rp "Enter a database name for WordPress: " DB_NAME
  fi
  DB_NAME=$(trim "${DB_NAME:-}")
  [[ -n "${DB_NAME}" ]] || die "Database name cannot be empty."

  if [[ -z "${DB_USER:-}" ]]; then
    read -rp "Enter a database username for WordPress: " DB_USER
  fi
  DB_USER=$(trim "${DB_USER:-}")
  [[ -n "${DB_USER}" ]] || die "Database user cannot be empty."
}
