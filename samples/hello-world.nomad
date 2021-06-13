job "hello" {
  datacenters = ["mushroom-kingdom"]

  type = "batch"

  group "hello" {
    count = 1

    task "say-hello" {
      driver = "exec"

      config {
        command = "echo"

        args = ["Hello", "world!"]
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
