#!/usr/bin/env bash

reload_services() {
  run_cmd nginx -t
  run_cmd systemctl enable --now nginx
  run_cmd systemctl reload nginx
  run_cmd systemctl enable --now mariadb
  run_cmd systemctl restart mariadb
  run_cmd systemctl enable --now "php${PHP_VERSION}-fpm"
  run_cmd systemctl reload "php${PHP_VERSION}-fpm"
  success "Services restarted."
}
