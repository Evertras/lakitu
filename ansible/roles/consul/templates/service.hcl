# See https://developer.hashicorp.com/consul/docs/discovery/services for the full definition
service {
  name = "{{ service_name }}"
  port = {{ service_port }}
}
