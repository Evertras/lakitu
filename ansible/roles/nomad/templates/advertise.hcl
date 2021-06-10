bind_addr = "{{ nomad_advertise_ip }}"

advertise {
  http = "{{ nomad_advertise_ip }}"
  rpc = "{{ nomad_advertise_ip }}"
  serf = "{{ nomad_advertise_ip }}"
}

