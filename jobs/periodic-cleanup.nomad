job "periodic-cleanup" {
  datacenters = ["mushroom-kingdom"]

  type = "batch"

  periodic {
    cron             = "*/5 * * * * *"
    prohibit_overlap = true
  }

  group "cleaner" {
    task "clean-nomad-periodics" {
      driver = "raw_exec"

      template {
        data = <<-EOF
        {{ with service "http.nomad" -}}
        {{ with index . 0 -}}
        export NOMAD_ADDR=http://{{ .Address }}:{{ .Port }}
        {{- end }}
        {{- end }}
        EOF

        destination = "local/nomad_servers.env"
      }

      config {
        command = "bash"
        args = [
          "-c",
          <<-EOF
          set -eo pipefail
          source local/nomad_servers.env
          DEAD_IDS=$(nomad status | grep ' dead ' | grep -E '/periodic-[0-9]+ ' | awk '{ print $1 }')
          JOBS=$(awk -F'/' '{ print $1 }' <<< "$DEAD_IDS" | sort -u)
          for JOB in $JOBS; do
            grep "$JOB/periodic-" <<< "$DEAD_IDS" | head -n-5 | xargs -I{} -P5 nomad stop -purge {}
          done
          EOF
        ]
      }
    }
  }
}
