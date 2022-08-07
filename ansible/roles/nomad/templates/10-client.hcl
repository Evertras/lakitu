client {
  enabled = true

  network_interface = "{{ nomad_network_interface }}"
}

{% if nomad_raw_exec_enabled|bool %}
plugin "raw_exec" {
  config {
    enabled = true
  }
}
{% endif %}
