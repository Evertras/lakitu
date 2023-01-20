job "weave-cleanup" {
  datacenters = ["mushroom-kingdom"]

  type = "sysbatch"

  periodic {
    cron             = "* * * * * *"
    prohibit_overlap = true
  }

  group "cleaner" {
    task "clean-old-interfaces" {
      driver = "raw_exec"

      config {
        command = "bash"
        # https://github.com/weaveworks/weave/issues/3406
        args = [
          "-c",
          <<-EOF
          ip a | grep 'vethwepl.*\@' -oP | while read -r line ; do
              veth=$$${line::-1}
              if [[ $veth =~ [0-9] ]]; then
                echo check $veth
                pid=$(echo $veth | tr -dc '0-9')
                if ! ps -p $pid > /dev/null; then
                  echo deleting $veth
                  ip link delete $veth >&2
                else
                  echo $veth still running
                fi
              else
                echo $veth veth has no number in it and will not be deleted
              fi
          done
          EOF
        ]
      }
    }
  }
}
