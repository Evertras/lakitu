data_dir   = "/opt/consul"
encrypt    = "{{ consul_encryption_key }}"
log_level  = "INFO"
node_name  = "{{ inventory_hostname }}"
retry_join = ["{{ hostvars['lakitu'].ansible_host }}"]

bind_addr = "{{ advertise_ip }}"

# Enable these for TLS later
verify_incoming = false
verify_outgoing = false
verify_server_hostname = false

