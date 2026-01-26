#!/usr/bin/env bash

usage() {
  cat <<USAGE
${BOLD}WordPress Production Installer${RESET}

${BOLD}Usage:${RESET} $0 [options]

${BOLD}Options:${RESET}
  --verbose          Show full command output.
  --quiet            Hide most command output (default behavior).
  --hide-secrets     Mask sensitive values in the final summary.
  --no-colour        Disable coloured output.
  --non-interactive  Require environment variables for inputs.
  --dangerous        Purge MariaDB, Nginx, and /var/www/html after confirmation (irreversible).
  -h, --help         Show this help message.

${BOLD}Environment Variables (for --non-interactive mode):${RESET}
  WEBSITE_NAME            Domain name (e.g., example.com)
  CERTBOT_EMAIL           Email for Let's Encrypt notifications
  DB_NAME                 Database name for WordPress
  DB_USER                 Database username for WordPress
  DB_PASSWORD             Database password for WordPress
  CERT_METHOD             Certificate method: 'cloudflare' or 'http' (default: cloudflare)
  CLOUDFLARE_API_TOKEN    Required if CERT_METHOD=cloudflare and ${CLOUDFLARE_INI} doesn't exist

${BOLD}Examples:${RESET}
  sudo ./install.sh --verbose --hide-secrets
  
  WEBSITE_NAME=example.com \\
  CERTBOT_EMAIL=admin@example.com \\
  CERT_METHOD=http \\
  DB_NAME=wordpress \\
  DB_USER=wpuser \\
  DB_PASSWORD='SecurePass123!' \\
  sudo ./install.sh --non-interactive

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

print_header() {
  echo
  echo -e "${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║                                                            ║${RESET}"
  echo -e "${BOLD}║${RESET}     ${BLUE}${BOLD}WordPress Production Installer${RESET}                      ${BOLD}║${RESET}"
  echo -e "${BOLD}║                                                            ║${RESET}"
  echo -e "${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
  echo
}

print_section() {
  local title="$1"
  echo
  echo -e "${BOLD}${BLUE}▶ ${title}${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

prompt_inputs() {
  if [[ ${NON_INTERACTIVE} -eq 1 ]]; then
    local required_vars=(WEBSITE_NAME CERTBOT_EMAIL DB_NAME DB_USER DB_PASSWORD)

    # Handle CERT_METHOD for non-interactive mode
    CERT_METHOD=$(trim "${CERT_METHOD:-cloudflare}")
    
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

  print_header

  print_section "Domain Configuration"
  if [[ -z "${WEBSITE_NAME:-}" ]]; then
    echo -ne "${GREEN}➜${RESET} Enter your domain (e.g. example.com): "
    read -r WEBSITE_NAME
  fi
  WEBSITE_NAME=$(trim "${WEBSITE_NAME:-}")
  [[ -n "${WEBSITE_NAME}" ]] || die "Domain name cannot be empty."
  echo -e "   ${BOLD}Domain:${RESET} ${WEBSITE_NAME}"

  print_section "SSL Certificate Configuration"
  if [[ -z "${CERT_METHOD:-}" ]]; then
    echo
    echo -e "  ${BOLD}Select SSL certificate method:${RESET}"
    echo
    echo -e "    ${GREEN}1)${RESET} Cloudflare DNS Challenge (recommended for wildcard certs)"
    echo -e "       ${BLUE}→${RESET} Requires Cloudflare API token"
    echo -e "       ${BLUE}→${RESET} Supports wildcard certificates (*.${WEBSITE_NAME})"
    echo
    echo -e "    ${GREEN}2)${RESET} HTTP Challenge (standard)"
    echo -e "       ${BLUE}→${RESET} No API token required"
    echo -e "       ${BLUE}→${RESET} Domain must be pointed to this server"
    echo -e "       ${BLUE}→${RESET} Only covers the main domain (no wildcard)"
    echo
    local cert_choice
    while true; do
      echo -ne "${GREEN}➜${RESET} Enter your choice [1/2]: "
      read -r cert_choice
      cert_choice=$(trim "${cert_choice}")
      
      case "${cert_choice}" in
        1)
          CERT_METHOD="cloudflare"
          echo -e "   ${BOLD}Method:${RESET} Cloudflare DNS Challenge"
          break
          ;;
        2)
          CERT_METHOD="http"
          echo -e "   ${BOLD}Method:${RESET} HTTP Challenge"
          break
          ;;
        *)
          echo -e "   ${RED}✗${RESET} Invalid choice. Please enter 1 or 2."
          ;;
      esac
    done
  fi

  print_section "Contact Information"
  if [[ -z "${CERTBOT_EMAIL:-}" ]]; then
    echo -ne "${GREEN}➜${RESET} Enter email for Let's Encrypt notifications: "
    read -r CERTBOT_EMAIL
  fi
  CERTBOT_EMAIL=$(trim "${CERTBOT_EMAIL:-}")
  [[ -n "${CERTBOT_EMAIL}" ]] || die "Email is required for certificate issuance."
  echo -e "   ${BOLD}Email:${RESET} ${CERTBOT_EMAIL}"

  DOCUMENT_ROOT="${DOCUMENT_ROOT_BASE}/${WEBSITE_NAME}"

  print_section "Database Configuration"
  if [[ -z "${DB_NAME:-}" ]]; then
    echo -ne "${GREEN}➜${RESET} Enter a database name for WordPress: "
    read -r DB_NAME
  fi
  DB_NAME=$(trim "${DB_NAME:-}")
  [[ -n "${DB_NAME}" ]] || die "Database name cannot be empty."
  echo -e "   ${BOLD}Database:${RESET} ${DB_NAME}"

  if [[ -z "${DB_USER:-}" ]]; then
    echo -ne "${GREEN}➜${RESET} Enter a database username for WordPress: "
    read -r DB_USER
  fi
  DB_USER=$(trim "${DB_USER:-}")
  [[ -n "${DB_USER}" ]] || die "Database user cannot be empty."
  echo -e "   ${BOLD}Username:${RESET} ${DB_USER}"
  
  echo
  echo -e "${BOLD}${GREEN}✓${RESET} Configuration complete!${RESET}"
  echo
}
