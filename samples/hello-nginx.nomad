job "hello-nginx" {
  datacenters = ["mushroom-kingdom"]

  type = "service"

  group "hello" {
    count = 1

    network {
      port "http" {
        to = -1
      }
    }

    service {
      name = "hello-nginx"
      port = "http"

      meta {
        thing = "cool"
      }
    }

    task "say-hello" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
      }
    }
  }
}
