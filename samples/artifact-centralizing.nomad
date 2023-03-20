# Demonstrates a simple way to centralize logs and artifacts to a controller
# of some sort using built-in Nomad CLI tools.
job "artifact-centralizing" {
  datacenters = ["mushroom-kingdom"]

  type = "batch"

  group "docker-dostuff" {
    task "tick-up" {
      driver = "docker"

      config {
        image = "ubuntu:22.04"
        command = "/bin/bash"

        # This directory name is arbitrary but must be agreed on between tasks
        volumes = [
          "centralize/tick-up:/var/log/output"
        ]

        args = [
          "-c",
          <<-EOF
          # This would normally be wherever the application is normally logging,
          # the important thing is that it matches the volume above.
          mkdir -p /var/log/output/

          # Log to the known output directory
          function log {
            dest=/var/log/output/$$${1}.log

            echo $2 >> $dest
          }

          log x x
          log y y
          log z z

          log x "$(date)"
          log y "$(date)"
          log z "$(date)"

          for i in {0..60}; do
            log x $i
            log y $i
            log z $i
            sleep 1s
          done

          cat /var/log/output/x.log
          EOF
        ]
      }
    }
  }

  group "controller" {
    task "transfer-sidecar" {
      driver = "raw_exec"

      template {
        destination = "${NOMAD_ALLOC_DIR}/nomad-funcs.sh"

        data = <<-EOF
        {{ with service "http.nomad" }}
        {{ with index . 0 }}
        export NOMAD_ADDR=http://{{ .Address }}:{{ .Port }}
        {{ end }}
        {{ end }}

        function nomad-get-running-allocs() {
          nomad job allocs -verbose ${NOMAD_JOB_NAME} |
            grep -v ${NOMAD_ALLOC_ID} |
            awk '$7 == "run" {printf "%s %s", $1, $5}'
        }
        EOF
      }

      config {
        command = "bash"
        args = [
          "-c",
          <<-EOF
          sleep 5s
          set -x
          source ${NOMAD_ALLOC_DIR}/nomad-funcs.sh

          nomad-get-running-allocs
          EOF
        ]
      }
    }
  }
}
