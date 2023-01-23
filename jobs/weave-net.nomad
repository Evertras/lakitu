job "weave-system" {
  datacenters = ["mushroom-kingdom"]

  type = "system"

  group "weave" {
    task "launch" {
      driver = "raw_exec"

      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      artifact {
        source = "https://git.io/weave"
        destination = "alloc/weave"
        mode = "file"
      }

      config {
        command = "bash"
        args = [
          "-c",
          <<-EOF
          set -x
          chmod +x ./alloc/weave
          ./alloc/weave launch \
            --ipalloc-range 10.3.0.0/16 \
            --no-default-ipalloc \
            --no-restart \
            --no-dns \
            192.168.56.3 \
            192.168.56.4
          EOF
        ]
      }
    }

    task "attach" {
      resources {
        cpu    = 300
        memory = 200
      }

      driver = "raw_exec"

      config {
        command = "docker"
        args = [
          "attach", "weave",
        ]
      }
    }

    task "cleanup" {
      driver = "raw_exec"

      lifecycle {
        hook = "poststop"
      }

      config {
        command = "./alloc/weave"
        args = [ "stop" ]
      }
    }
  }
}
