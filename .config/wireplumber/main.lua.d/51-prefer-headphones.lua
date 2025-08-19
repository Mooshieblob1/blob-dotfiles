alsa_monitor.rules = alsa_monitor.rules or {}
table.insert(alsa_monitor.rules, {
  matches = {
    { { "device.name", "equals", "alsa_card.pci-0000_0c_00.4" }, },
  },
  apply_properties = {
    ["api.acp.auto-profile"] = false,
    ["api.acp.auto-port"] = false,
    ["device.routes"] = {
      { name = "analog-output-headphones", priority = 10000 },
      { name = "analog-output-lineout", priority = 9000 },
    },
  },
})
