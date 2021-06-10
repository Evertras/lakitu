datacenter = "dc1"

client {
  enabled = true
  servers = [
    "{{ hostvars['lakitu']['nomad_advertise_ip'] }}:4647",
  ]
}

