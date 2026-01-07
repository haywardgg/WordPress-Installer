#!/usr/bin/env bash

log() {
  echo -e "${BLUE}[INFO]${RESET} $*"
}

success() {
  echo -e "${GREEN}[OK]${RESET} $*"
}

warn() {
  echo -e "${YELLOW}[WARN]${RESET} $*"
}

die() {
  echo -e "${RED}[ERROR]${RESET} $*" >&2
  exit 1
}
