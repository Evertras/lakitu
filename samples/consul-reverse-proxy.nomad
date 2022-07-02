# TODO: Use better interrupt, filter based on metadata
job "consul-reverse-proxy" {
  datacenters = ["mushroom-kingdom"]

  type = "service"

  group "nginx-proxy" {
    count = 2

    network {
      mode = "host"

      port "http" {
        static = 80
      }
    }

    task "webserver" {
      driver = "docker"

      config {
        image = "nginx:1.23.0-alpine"
        ports = ["http"]
        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf:ro"
        ]
      }

      template {
        data = <<EOF
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

{{ range services }}
    upstream {{ .Name }} {
{{ range service .Name }}
      server {{ .Address }}:{{ .Port }};
{{ end }}
    }

    server {
      listen 80;
      server_name {{ .Name }}.mushroom-kingdom.local;
      location / {
        proxy_pass http://{{ .Name }};
      }
    }
{{ end }}
}

        EOF

        destination = "local/nginx.conf"
      }
    }
  }
}
