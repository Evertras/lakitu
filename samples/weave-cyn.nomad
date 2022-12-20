job "weave-cyn" {
  datacenters = ["mushroom-kingdom"]

  type = "service"

  group "mesh-client-1" {
    task "client" {
      driver = "docker"

      # 10.9.81.0/29 is 10.9.81.0 - 10.9.81.7
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

  group "outsider-broadcast" {
    count = 1

    task "broadcaster" {
      driver = "docker"

      # This subnet is separate from the others, so it should not receive anything
      # and it should not be able to send anything
      env {
        WEAVE_CIDR = "10.9.71.1/29"
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

        # Listen on ports to show we receive nothing, and try to send data (but fail!)
        data = <<EOF
listen-udp:
  - ":2000"
  - ":1234"
send-udp:
  - "10.9.81.7:2000"
  - "10.9.81.2:1234"
EOF
      }
    }
  }
}
