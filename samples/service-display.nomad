job "service-display" {
  datacenters = ["mushroom-kingdom"]

  type = "service"

  group "display-nginx" {
    count = 2

    network {
      port "http" {
        static = 80
      }
    }

    service {
      name = "service-displayer"
      port = "http"
    }

    task "webserver" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
        volumes = [
          "local/:/usr/share/nginx/html:ro"
        ]
      }

      template {
        data = <<EOF
<html>
<body>
  <h1>Services</h1>

{{ range services }}
  <h2>{{ .Name }}</h2>

  <ul>
{{- range service .Name }}
    <li>{{ .Address}}:{{ .Port }}</li>
{{- end }}
  </ul>

{{ end -}}

</body>
</html>
        EOF

        destination = "local/index.html"
      }
    }
  }
}
