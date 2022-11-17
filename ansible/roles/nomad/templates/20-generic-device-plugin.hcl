plugin "generic-device" {
  config {
    device {
      model = "idk"
      vendor = "lakitu"
      type = "{{ inventory_hostname }}"
    }
  }
}

