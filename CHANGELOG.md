# Changelog

## 1.1.0

- After a restart, the add-on waits until MQTT is connected, then reads the live level of each lighting group from C-Bus and publishes that state.
- If the C-Bus interface is not reachable when the add-on starts, it keeps trying instead of failing the start.
- If the MQTT broker drops out, the add-on retries for five minutes and then exits so the Supervisor can start it again.
- The documentation describes the current add-on behaviour, and that Home Assistant installs from `master` using the version in `config.yaml`.

## 1.0.3

- Home Assistant add-on for a Clipsal C-Bus PCI or CNI, using MQTT.
- Group addresses are dimmable lights unless listed as non-dimmable, switch, binary sensor, or ignore.
- Commands are queued, confirmed by the PCI, and retried.
