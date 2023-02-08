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
          source local/nomad_servers.env
          nomad status | grep ' dead ' | grep -E '/periodic-[0-9]+ ' | awk '{ print $1 }' | xargs -I{} nomad stop -purge {}
          EOF
        ]
      }
    }
  }
}
