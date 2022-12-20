################################################################################
# Weave + Cynomys demo
#
# Demonstrates connectivity between containers across different nodes using
# Weave as an overlay network, with specific subnets chosen.
#
# Subnet reference (.0 is unusable, .7/.255 is broadcast address)
# Weave default  - 10.8.0.0/20 (10.8.0.0 - 10.8.15.255)
# Main subnet    - 10.9.81.0/29 (10.9.81.0 - 10.9.81.7)
# Outside subnet - 10.9.71.0/29 (10.9.71.0 - 10.9.71.7)
#
# IP reference
# Broadcast     - 10.9.81.1
# Mesh client 1 - 10.9.81.2
# Mesh client 2 - 10.9.81.3
# Bad Broadcast - 10.9.71.1
################################################################################

job "weave-cyn" {
  datacenters = ["mushroom-kingdom"]

  type = "service"

  # Ensure they run on different nodes for demo purposes
  constraint {
    attribute = "${node.unique.id}"
    operator = "distinct_property"
    value = 2
  }

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

        # Do not go onto the local Docker network, Weave will add a network for us
        network_mode = "none"

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

        network_mode = "none"

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

        network_mode = "none"

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

        network_mode = "none"

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
