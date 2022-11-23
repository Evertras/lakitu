job "hello-weave" {
  datacenters = ["mushroom-kingdom"]

  type = "service"

  group "alpha-clients" {
    count = 5

    task "client" {
      driver = "docker"

      env {
        WEAVE_CIDR = "net:10.17.8.0/24"
      }

      resources {
        cpu    = 10
        memory = 10
      }

      config {
        image = "curlimages/curl"
        entrypoint = ["/bin/sh"]

        args = ["-c", <<EOF
        echo Hi alpha...
        ip addr | grep 10.17
        echo Running on 10.17.8.0/24, can talk to other alpha but not beta
        sleep 1h
        EOF
        ]
      }
    }
  }

  group "alpha-nginx" {
    task "nginx" {
      driver = "docker"

      env {
        WEAVE_CIDR = "net:10.17.8.0/24"
      }

      resources {
        cpu    = 10
        memory = 20
      }

      config {
        image = "nginx"
      }
    }
  }

  group "beta-clients" {
    count = 5

    task "client" {
      driver = "docker"

      env {
        WEAVE_CIDR = "net:10.17.11.0/24"
      }

      resources {
        cpu    = 10
        memory = 10
      }

      config {
        image = "curlimages/curl"
        entrypoint = ["/bin/sh"]

        args = ["-c", <<EOF
        echo Hi beta...
        ip addr | grep 10.17
        echo Running on 10.17.11.0/24, can talk to other beta but not alpha
        sleep 1h
        EOF
        ]
      }
    }
  }

  group "beta-nginx" {
    task "nginx" {
      driver = "docker"

      env {
        WEAVE_CIDR = "net:10.17.11.0/24"
      }

      resources {
        cpu    = 10
        memory = 20
      }

      config {
        image = "nginx"
      }
    }
  }
}
