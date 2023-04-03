job "taskapi-example" {
  type = "batch"

  group "taskapi-example" {

    task "taskapi" {
      driver = "docker"

      config {
        image = "curlimages/curl:7.87.0"
        args = [
          "--unix-socket", "${NOMAD_SECRETS_DIR}/api.sock",
          "-H", "Authorization: Bearer ${NOMAD_TOKEN}",
          "--data-binary", "{\"Meta\": {\"example\": \"Hello World!\"}}",
          "--fail-with-body",
          "--verbose",
          "localhost/v1/client/metadata",
        ]
      }

      identity {
        env = true
      }
    }
  }
}

