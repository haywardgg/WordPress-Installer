#!/usr/bin/env bash

configure_php() {
  PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
  PHP_FPM_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"

  if [[ ! -S "${PHP_FPM_SOCKET}" ]]; then
    warn "Expected PHP-FPM socket ${PHP_FPM_SOCKET} not found. Attempting to start php${PHP_VERSION}-fpm."
    run_cmd systemctl restart "php${PHP_VERSION}-fpm"
  fi

  local php_ini="/etc/php/${PHP_VERSION}/fpm/php.ini"
  if [[ -f "${php_ini}" ]]; then
    sed -i 's/^;*cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/' "${php_ini}"
    run_cmd systemctl reload "php${PHP_VERSION}-fpm"
    success "Adjusted PHP configuration (cgi.fix_pathinfo) for PHP ${PHP_VERSION}."
  else
    warn "PHP configuration file ${php_ini} not found."
  fi
}
