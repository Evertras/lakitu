datacenter = "dc1"

client {
  enabled = true
  servers = [
{% for host in nomad_servers %}
    "{{ hostvars[host].nomad_advertise_ip }}:4647",
{% endfor %}
  ]
}

