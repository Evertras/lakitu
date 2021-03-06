datacenter = "{{ datacenter }}"
data_dir   = "/opt/consul"
encrypt    = "{{ consul_encryption_key }}"
log_level  = "INFO"
node_name  = "{{ inventory_hostname }}"
retry_join = ["{{ hostvars['lakitu'].advertise_ip }}"]

bind_addr = "{{ advertise_ip }}"

ca_file = "/etc/consul.d/ca.pem"

verify_incoming = true
verify_outgoing = true
verify_server_hostname = true
