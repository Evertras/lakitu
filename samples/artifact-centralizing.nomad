variables {
  # Something that won't collide... do NOT use a space anywhere in here!
  prefix = "__centralized-artifacts__"
}

# Demonstrates a simple way to centralize logs and artifacts to a controller
# of some sort using built-in Nomad CLI tools.
job "artifact-centralizing" {
  datacenters = ["mushroom-kingdom"]

  type = "batch"

  group "dostuff" {
    task "no-artifacts" {
      driver = "docker"

      config {
        image = "ubuntu:22.04"
        command = "bash"

        args = [
          "-c",
          <<-EOF
            # No centralized artifacts produced here
            echo "Doing something important..."
            sleep 5s
            echo "Done doing stuff!"
          EOF
        ]
      }
    }

    task "tick-up" {
      driver = "docker"

      config {
        image = "ubuntu:22.04"
        command = "/bin/bash"

        volumes = [
          "${var.prefix}/:/var/log/output"
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

          for i in {0..60..6}; do
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
    task "watch-logs" {
      driver = "docker"

      config {
        image = "ubuntu:22.04"
        command = "/bin/bash"
        args = [
          "-c",
          <<-EOF
          function wait-for-60() {
            # Just a dumb loop for demo purposes
            until grep 60 $1; do
              echo "Still waiting for $1..."
              sleep 1s
            done

            echo ">> Saw 60 for $1!"
          }

          # We expect to see the value of 60 in each of the artifact logs from
          # the other task group, so loop until we see it...
          wait-for-60 /var/log/output/tick-up/x.log &
          wait-for-60 /var/log/output/tick-up/y.log &
          wait-for-60 /var/log/output/tick-up/z.log &

          # Wait for all the above to finish before moving on
          wait

          EOF
        ]

        volumes = [
          "${var.prefix}:/var/log/output"
        ]
      }
    }

    task "ts" {
      driver = "raw_exec"

      lifecycle {
        # This will tell Nomad to restart it as often as necessary
        # https://developer.hashicorp.com/nomad/docs/job-specification/lifecycle#sidecar
        sidecar = true
      }

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
            awk '$7 == "run" {print $1}'
        }

        function nomad-get-fs() {
          echo "Checking alloc $1"
          subdirs=$(nomad alloc fs "$1" | tail -n+2 | awk '$5 != "alloc/" { print $5 }')

          for subdir in $subdirs; do
            # -H gets us the byte size in output
            if contents=$(nomad alloc fs -H "$1" "$${subdir}/${var.prefix}"); then
              echo "  > Found dir for $subdir"

              # Note: This will BREAK for anything with a space in the filename!
              files=$(tail -n+2 <<< "$contents" | awk '{print $4}')

              # This is a bit nasty, but hardcode into the other task directory...
              # the Nomad docker driver doesn't like trying to use ${NOMAD_ALLOC_DIR}
              # for a volume without some explicit security flags.
              dir="../watch-logs/${var.prefix}/$${subdir}"
              mkdir -p $dir
              for file in $files; do
                # Start tailing the file in the background
                nomad alloc fs -f $1 "$${subdir}/${var.prefix}/$${file}" > $${dir}/$${file} &
              done
            else
              echo "  > Skipping $subdir, no centralized artifacts found"
            fi
          done
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

          ls ../watch-logs
          #mkdir -p ../${var.prefix}

          allocs=$(nomad-get-running-allocs)

          for alloc in $$${allocs}; do
            echo Checking $$${alloc}
            nomad-get-fs $$${alloc}
          done

          # This will never return, but the idea is that we wait for all
          # background tasks to be "done"
          wait
          EOF
        ]
      }
    }
  }
}
