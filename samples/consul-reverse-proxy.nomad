# TODO: Use better interrupt
job "consul-reverse-proxy" {
  datacenters = ["mushroom-kingdom"]

  type = "system"

  group "nginx-proxy" {
    network {
      mode = "host"

      port "http" {
        static = 80
      }
    }

    task "proxy" {
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

    # Default to 404 if nothing matches
    server {
      listen 80 default_server;
      server_name _;
      return 404;
    }

    # Expose Nomad itself for funsies/playing
    upstream nomad {
{{ range service "nomad" }}
      server {{ .Address }}:{{ .Port }};
{{ end }}
    }

    server {
      listen 80;
      server_name nomad.mushroom-kingdom;
      location / {
        proxy_pass http://nomad;
      }
    }

    # Expose all services with the "exposed" tag
{{ range services }}
{{ if .Tags | contains "exposed" }}
    upstream {{ .Name }} {
{{ range service .Name }}
      server {{ .Address }}:{{ .Port }};
{{ end }}
    }

    server {
      listen 80;
      server_name {{ .Name }}.mushroom-kingdom;
      location / {
        proxy_pass http://{{ .Name }};
      }
    }
{{ end }}
{{ end }}
}

        EOF

        destination = "local/nginx.conf"
      }
    }
  }
}
