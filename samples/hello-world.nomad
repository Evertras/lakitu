job "hello" {
  datacenters = ["mushroom-kingdom"]

  type = "batch"

  group "hello" {
    count = 1

    task "say-hello" {
      driver = "exec"

      config {
        command = "echo"

        args = ["Hello", "${node.unique.name}!"]
      }

      resources {
        # Reserve a Doyota Mius to drive around with for the duration of this task
        device "doyota/car/mius" {}
      }
    }

    task "hostname" {
      driver = "exec"

      config {
        command = "hostname"
      }
    }
  }
}
