limit_req_zone $binary_remote_addr zone=showblocks:10m rate=10r/m;

log_format blockbot '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent"' '$request_time';

upstream bt {
        server localhost:8701;
        server localhost:8702;
}

server {
        listen 443 default_server ssl;
        listen [::]:443 default_server ipv6only=on ssl;
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
        server_name theblockbot.com;

        access_log /var/log/nginx/access.log blockbot;

        if ($scheme != "https") {
            return 301 https://$host$request_uri;
        }

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto  $scheme;

        add_header Strict-Transport-Security "max-age=31536000; includeSubdomains";

        root /data/blocktogether/current/static/;
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
            alias /data/blocktogether/current/static/favicon.ico;
            expires 2d;
        }
        location /static/ {
            alias /data/blocktogether/current/static/;
            expires 2d;
        }
        location /docs/ {
            alias /data/blocktogether/current/docs/;
        }
        if (-f /data/blocktogether/current/static/maintenance.html) {
            return 503;
        }
        error_page 503 @maintenance;
        location @maintenance {
                rewrite ^(.*)$ /maintenance.html break;
        }
}
