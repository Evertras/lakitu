job "weave-cyn" {
  datacenters = ["mushroom-kingdom"]

  type = "service"

  group "mesh-client-1" {
    task "client" {
      driver = "docker"

      env {
        WEAVE_CIDR = "10.9.81.2/29"
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
  - ":1234"
send-udp:
  - "10.9.81.3:1234"
EOF
      }
    }
  }

  group "mesh-client-2" {
    task "client" {
      driver = "docker"

      env {
        WEAVE_CIDR = "10.9.81.3/29"
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
  - ":1234"
send-udp:
  - "10.9.81.2:1234"
EOF
      }
    }
  }

  group "mesh-broadcast" {
    count = 1

    task "broadcaster" {
      driver = "docker"

      env {
        WEAVE_CIDR = "10.9.81.1/29"
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
 - "10.9.81.7:2000"
EOF
      }
    }
  }
}
