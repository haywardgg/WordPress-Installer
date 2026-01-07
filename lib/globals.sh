#!/usr/bin/env bash

if [[ -t 1 ]]; then
  BLUE="\033[34m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  RED="\033[31m"
  BOLD="\033[1m"
  RESET="\033[0m"
else
  BLUE=""
  GREEN=""
  YELLOW=""
  RED=""
  BOLD=""
  RESET=""
fi

disable_colours() {
  BLUE=""
  GREEN=""
  YELLOW=""
  RED=""
  BOLD=""
  RESET=""
}

NGINX_CONF_DIR="/etc/nginx"
AVAILABLE_SITES_DIR="${NGINX_CONF_DIR}/sites-available"
ENABLED_SITES_DIR="${NGINX_CONF_DIR}/sites-enabled"
DOCUMENT_ROOT_BASE="/var/www/html"
SECRETS_DIR="/root/.secrets"
CLOUDFLARE_INI="${SECRETS_DIR}/cloudflare.ini"
MARIADB_ROOT_PASS_FILE="${SECRETS_DIR}/mariadb-root.pass"
NGINX_USER="www-data"
NGINX_GROUP="www-data"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

CREATED_ROOT_USER=0
ROOT_PASSWORD_STATUS="unset"
REUSE_EXISTING_STACK=0
RAW_OUTPUT=0
HIDE_SECRETS=0
NO_COLOUR=0
NON_INTERACTIVE=0
DANGEROUS_MODE=0
