client {
  enabled = true

  network_interface = "{{ nomad_network_interface }}"
}

plugin "docker" {
  config {
    endpoint = "unix:///var/run/weave/weave.sock"
  }
}

{% if nomad_raw_exec_enabled|bool %}
plugin "raw_exec" {
  config {
    enabled = true
  }
}
{% endif %}
