job "weave-cyn" {
  datacenters = ["mushroom-kingdom"]

  type = "service"

  group "mesh-client" {
    count = 5

    task "client" {
      driver = "docker"

      env {
        WEAVE_CIDR = "net:10.9.81.0/24"
      }

      resources {
        cpu    = 10
        memory = 10
      }

      config {
        image = "evertras/cynomys"

        args = ["-c", "/config.yaml"]

        volumes = [
          "config.yaml:/config.yaml"
        ]
      }

      template {
        destination = "config.yaml"

        data = <<EOF
listen-udp:
  - ":2000"
EOF
      }
    }
  }

  group "mesh-broadcast" {
    count = 2

    task "broadcaster" {
      driver = "docker"

      env {
        WEAVE_CIDR = "net:10.9.81.0/24"
      }

      resources {
        cpu    = 10
        memory = 10
      }

      config {
        image = "evertras/cynomys"

        args = ["-c", "/config.yaml"]

        volumes = [
          "config.yaml:/config.yaml"
        ]
      }

      template {
        destination = "config.yaml"

        data = <<EOF
send-udp:
  - "10.9.81.255:2000"
EOF
      }
    }
  }
}
