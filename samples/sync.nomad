variables {
  # How many individual parts to run concurrently
  part_count = 8
}

# Demonstrates how to synchronize flows with Consul
job "sync" {
  datacenters = ["mushroom-kingdom"]

  type = "batch"

  # Run some number of jobs that take different times to prepare, then run
  # them in sync!
  #
  # Our states go from (preparing -> prepared) -> (initializing -> running)
  # Preparing/prepared are in the pretask, and initializing/running are in the main task.
  #
  # We gate all tasks to coordinate to wait for all other tasks to reach prepared
  # before moving to the main task.  A separate task is waiting for all the
  # synced tasks to reach "running" before it declares the gate is passed, as
  # a further example of potential usage.
  group "dostuff" {
    count = var.part_count

    task "prepare" {
      driver = "raw_exec"

      lifecycle {
        hook = "prestart"
      }

      template {
        destination = "${NOMAD_ALLOC_DIR}/consul-funcs.sh"

        data = <<-EOF
        CONSULDIRJOB=jobs/${NOMAD_JOB_NAME}
        CONSULDIRGROUP=${CONSULDIRJOB}/group/${NOMAD_GROUP_NAME}-${NOMAD_ALLOC_INDEX}

        function consul-increment {
          KEY=$1

          CURRENT=$(consul kv get -detailed ${KEY} || echo -n "none")

          MODIFY_INDEX=0
          TARGET_VALUE=1

          if [[ ${CURRENT} != "none" ]]; then
            MODIFY_INDEX=$(echo "${CURRENT}" | grep ^ModifyIndex | awk '{print $2}')
            TARGET_VALUE=$(($(echo "${CURRENT}" | grep ^Value | awk '{print $2}') + 1))
          fi

          echo "Setting ${KEY} to ${TARGET_VALUE} with modify index ${MODIFY_INDEX}"

          RESULT=$(consul kv put -cas -modify-index ${MODIFY_INDEX} ${KEY} ${TARGET_VALUE} 2>&1)

          CAS_FAIL=$(echo "$RESULT" | grep CAS)

          if [[ -n ${CAS_FAIL} ]]; then
            echo "CAS failed, retrying..."
            consul-increment $KEY
          fi
        }

        # Register ourselves as preparing
        function consul-set-state {
          STATE=$1

          consul kv put ${CONSULDIRGROUP}/state ${STATE}

          consul-increment ${CONSULDIRJOB}/states/${STATE}
        }

        function consul-wait-for-state {
          STATE=$1

          echo -n "Waiting for ${STATE}."

          # The total number of tasks that are running
          EXPECTED_VALUE=${var.part_count}
          ACTUAL_VALUE=0

          # No retry timeouts or anything for now...
          until [[ $EXPECTED_VALUE -eq $ACTUAL_VALUE ]]; do
            echo -n .
            ACTUAL_VALUE=$(consul kv get $CONSULDIRJOB/states/${STATE})
            sleep 1s
          done
          echo " Done!"
        }
        EOF
      }

      config {
        command = "bash"
        args = [
          "-c",
          <<-EOF
          source ${NOMAD_ALLOC_DIR}/consul-funcs.sh

          consul-set-state preparing

          # Pretend we're doing something that takes a while
          echo "Starting some big task..."
          date

          # Note that bash math is whole numbers only, so we're bunching together
          # some to hope for a race condition, with minimum 2 second wait
          WAIT_TIME=$((${NOMAD_ALLOC_INDEX} / 4 + 2))
          echo "(Waiting $$${WAIT_TIME} seconds)"
          sleep $$${WAIT_TIME}s
          echo "Done with the big task, we're now prepared!"
          consul-set-state prepared
          consul-wait-for-state prepared
          date
          EOF
        ]
      }
    }

    task "run" {
      driver = "raw_exec"

      config {
        command = "bash"
        args = [
          "-c",
          <<-EOF
          source ${NOMAD_ALLOC_DIR}/consul-funcs.sh

          echo "Starting the main task"
          date
          consul-set-state initializing

          # Note that bash math is whole numbers only, so we're bunching together
          # some to hope for a race condition, with minimum 2 second wait
          WAIT_TIME=$((${NOMAD_ALLOC_INDEX} / 4 + 2))
          echo "(Waiting $$${WAIT_TIME} seconds)"
          date
          sleep $$${WAIT_TIME}s
          date
          echo "Done initializing, now running"
          consul-set-state running
          echo "Main task started!"

          EOF
        ]
      }
    }
  }

  group "observer" {
    task "cleanup" {
      driver = "raw_exec"

      lifecycle {
        hook = "poststop"
      }

      config {
        command = "bash"
        args = [
          "-c",
          <<-EOF
          date
          # Comment this out to poke around in Consul manually, this is just
          # so we can run multiple times in a row to show functionality.
          # You may need to run this command manually on the vagrant box if
          # something goes wrong.
          consul kv delete -recurse jobs/${NOMAD_JOB_NAME}
          EOF
        ]
      }
    }

    task "observe" {
      driver = "raw_exec"

      template {
        destination = "${NOMAD_ALLOC_DIR}/consul-funcs.sh"

        data = <<-EOF
        CONSULDIRJOB=jobs/${NOMAD_JOB_NAME}

        function consul-wait-for-state {
          STATE=$1

          echo -n "Waiting for $STATE."

          # The total number of tasks that are running
          EXPECTED_VALUE=${var.part_count}
          ACTUAL_VALUE=0

          # No retry timeouts or anything for now...
          until [[ $EXPECTED_VALUE -eq $ACTUAL_VALUE ]]; do
            echo -n .
            ACTUAL_VALUE=$(consul kv get ${CONSULDIRJOB}/states/${STATE})
            sleep 1s
          done
          echo " Done!"
        }
        EOF
      }

      config {
        command = "bash"
        args = [
          "-c",
          <<-EOF
          source ${NOMAD_ALLOC_DIR}/consul-funcs.sh

          echo "Demonstrating waiting for states from outside source"

          date
          consul-wait-for-state prepared
          date
          consul-wait-for-state running
          date
          echo "Running!  Now we can do things..."
          EOF
        ]
      }
    }
  }
}
