job "service-display" {
  datacenters = ["mushroom-kingdom"]

  type = "system"

  group "display-nginx" {
    network {
      mode = "host"
      port "http" {
        static = 8787
        to = 80
      }
    }

    service {
      name = "service-displayer"
      port = "http"
      tags = [
        "exposed",
      ]
    }

    task "webserver" {
      driver = "docker"

      config {
        image = "nginx:1.23.0-alpine"
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
