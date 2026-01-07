server {
    listen 80;
    listen [::]:80;
    server_name ${WEBSITE_NAME};
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    root ${DOCUMENT_ROOT};
    index index.php index.html;
    server_name ${WEBSITE_NAME};

    ssl_certificate /etc/letsencrypt/live/${WEBSITE_NAME}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${WEBSITE_NAME}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 5m;

    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";

    client_max_body_size 64M;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|xls|xlm)$ {
        expires max;
        log_not_found off;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_FPM_SOCKET};
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    access_log /var/log/nginx/${WEBSITE_NAME}.access.log;
    error_log /var/log/nginx/${WEBSITE_NAME}.error.log;
}
