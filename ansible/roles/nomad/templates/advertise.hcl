bind_addr = "{{ advertise_ip }}"

advertise {
  http = "{{ advertise_ip }}"
  rpc = "{{ advertise_ip }}"
  serf = "{{ advertise_ip }}"
}

