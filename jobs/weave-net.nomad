job "weave-net" {
  datacenters = ["mushroom-kingdom"]

  type = "system"

  group "weave" {
    restart {
      interval = "5m"
      attempts = 5
      delay = "10s"
      mode = "delay"
    }

    service {
      name = "weave-server"
    }

    task "install" {
      driver = "raw_exec"

      lifecycle {
        hook = "prestart"
      }

      artifact {
        source = "https://git.io/weave"
        destination = "alloc/weave"
        mode = "file"
      }

      # Install to a dedicated directory rather than potentially do destructive
      # things on the host machine.  We install here so that other jobs can also
      # run the weave CLI for doing things like rmpeer cleanup, etc.
      config {
        command = "bash"
        args = [
          "-c",
          <<-EOF
          chmod +x ./alloc/weave
          # This is not good for a production environment, but easy for lakitu use
          cp ./alloc/weave /usr/local/bin/weave
          EOF
        ]
      }
    }

    task "weave" {
      resources {
        cpu    = 300
        memory = 200
      }

      driver = "raw_exec"

      template {
        data = <<-EOF
        {{- range service "weave-server" }}{{ .Address }} {{ end }}
        EOF

        destination = "local/weave_peers"
      }

      config {
        command = "bash"
        args = [
          "-c", <<-EOF
          set -x
          WEAVE_STATUS_ADDR=0.0.0.0:6782 weave launch \
            --ipalloc-range 10.8.0.0/13 \
            --no-default-ipalloc \
            --no-restart \
            --no-dns \
            --without-dns \
            --no-discovery \
            $(cat local/weave_peers)
          docker attach weave
          EOF
        ]
      }
    }

    task "cleanup" {
      driver = "raw_exec"

      lifecycle {
        hook = "poststop"
      }

      config {
        command = "weave"
        args = [ "stop" ]
      }
    }
  }
}
