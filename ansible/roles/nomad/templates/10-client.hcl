client {
  enabled = true
  servers = [
{% for host in nomad_servers %}
    "{{ hostvars[host].advertise_ip }}:4647",
{% endfor %}
  ]
}

