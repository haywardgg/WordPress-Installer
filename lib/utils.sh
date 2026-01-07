#!/usr/bin/env bash

run_cmd() {
  if [[ ${RAW_OUTPUT} -eq 1 ]]; then
    "$@"
  else
    if ! output=$("$@" 2>&1); then
      echo -e "${RED}[ERROR]${RESET} ${output}" >&2
      return 1
    fi
  fi
}

with_raw_output() {
  local previous_raw_output="${RAW_OUTPUT}"
  RAW_OUTPUT=1

  "$@"
  local status=$?

  RAW_OUTPUT="${previous_raw_output}"
  return ${status}
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "This script must be run as root."
  fi
}

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s' "${value}"
}

mask_secret() {
  if [[ ${HIDE_SECRETS} -eq 1 ]]; then
    printf '[hidden]'
  else
    printf '%s' "$1"
  fi
}

generate_password() {
  openssl rand -base64 29 | tr -d '=+/' | cut -c1-25
}

on_exit() {
  local status=$?

  if [[ ${status} -ne 0 ]]; then
    warn "Installation failed (exit code: ${status})."

    if [[ ${CREATED_ROOT_USER} -eq 1 && -n "${MYSQL_ROOT_PASSWORD:-}" ]]; then
      local root_pw_output
      root_pw_output=$(mask_secret "${MYSQL_ROOT_PASSWORD}")

      echo
      echo "MySQL root credentials created during this run:" >&2
      echo "  username: root" >&2
      echo "  password: ${root_pw_output}" >&2
    fi
  fi
}
