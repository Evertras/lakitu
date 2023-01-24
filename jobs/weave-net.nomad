job "weave-net" {
  datacenters = ["mushroom-kingdom"]

  type = "system"

  group "weave" {
    service {
      name = "weave-net-agent"
    }

    network {
      port "weave-net" {
        static = 6789
      }
    }

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

      template {
        data = <<-EOF
        {{- range service "weave-net-agent" }}{{ .Address }} {{ end }}
        EOF

        destination = "local/weave_peers"
      }

      config {
        command = "bash"
        args = [
          "-c",
          <<-EOF
          set -x
          chmod +x ./alloc/weave
          ./alloc/weave stop || echo "No existing weave found, this is fine"
          ./alloc/weave launch \
            --ipalloc-range 10.3.0.0/16 \
            --no-default-ipalloc \
            --no-restart \
            --no-dns \
            $(cat local/weave_peers)
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
