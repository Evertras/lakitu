# Runs a container that pretends to be unhealthy to see how Nomad reacts
job "health" {
  datacenters = ["mushroom-kingdom"]

  type = "service"

  group "health" {
    count = 1

    task "health" {
      driver = "docker"

      config {
        image = "evertras/health-sandbox:1.0.0"
      }
    }
  }
}
