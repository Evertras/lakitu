api_addr = "{{ advertise_ip }}:8200"

listener "tcp" {
  address = "{{ advertise_ip }}:8200"

  # Enable this later!
  tls_disable = "true"
}

storage "file" {
  path = "/tmp/vault"
}

ui = true

