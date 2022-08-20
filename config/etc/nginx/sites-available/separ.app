limit_req_zone $binary_remote_addr zone=showblocks:10m rate=10r/m;

log_format blockbot '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent"' '$request_time';

upstream bt {
        server localhost:3000;
}

server {
        # NB: This WILL NOT work without the certbot configuration being ran
        # Certbot adds all the required SSL configuration to this file
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
        server_name separ.app;

        access_log /var/log/nginx/access.log blockbot;

        if ($scheme != "https") {
            return 301 https://$host$request_uri;
        }

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto  $scheme;

        add_header Strict-Transport-Security "max-age=31536000; includeSubdomains";

        root /etc/blocktogether/static/;
        location / {
                proxy_pass http://bt;
                proxy_read_timeout 45s;
        }
        location /show-blocks/ {
                limit_req zone=showblocks burst=5;
                proxy_pass http://bt;
                proxy_read_timeout 45s;
        }
        location /favicon.ico {
            alias /etc/blocktogether/static/favicon.ico;
            expires 2d;
        }
        location /static/ {
            alias /etc/blocktogether/static/;
            expires 2d;
        }
        location /docs/ {
            alias /etc/blocktogether/docs/;
        }
        if (-f /etc/blocktogether/static/maintenance.html) {
            return 503;
        }
        error_page 503 @maintenance;
        location @maintenance {
                rewrite ^(.*)$ /maintenance.html break;
        }
        location /settings {
          auth_basic "Restricted";
          auth_basic_user_file /etc/blocktogether/static/.htpasswd;
          proxy_pass http://bt;
          proxy_read_timeout 45s;
        }
}
