# Integrate Clipsal C-Bus with Home Assistant

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

This add-on bridges a Clipsal C-Bus PCI or CNI to Home Assistant over MQTT. It is a fork of [cmqttd](https://github.com/micolous/cbus) by Michael Farrell, packaged for Home Assistant.

Group addresses are dimmable lights unless you list them as something else:

- **Non-dimmable lights** are on/off only.
- **Switches** are on/off controls.
- **Binary sensors** report state and do not accept commands.
- **Ignored** addresses are not published to MQTT.

On startup the bridge connects to C-Bus, waits until MQTT is connected, then reads the live level of each lighting group and publishes that state. Wall and app changes after that are passed through as they happen. A later MQTT reconnect does not publish discovery again or re-read every level, unless a change was missed while the broker was down. Every entity is created under one C-Bus device.

Leave the MQTT broker, username, and password blank to use the Mosquitto add-on. A broker you have already saved continues to be used.

The image is built for 64-bit Home Assistant only (`aarch64` and `amd64`). Home Assistant no longer publishes base images for `armhf`, `armv7`, or `i386`.

If the MQTT broker disappears, the add-on retries for five minutes. If the broker is still down, the add-on exits so the Supervisor can start it again.

## Versions

Home Assistant installs this add-on from the `master` branch. The version it offers is the `version` field in [`config.yaml`](config.yaml) on that branch. There is no version picker.

`beta` is a development branch. Home Assistant will not offer it as an update.

## Installation

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/wazza-aus/cbus2ha)

Click the button above to add this repository. To add it yourself:

1. In Home Assistant, go to **Settings** → **Add-ons** → **Add-on Store**.
2. Open the three-dot menu (⋮) and select **Repositories**.
3. Add `https://github.com/wazza-aus/cbus2ha`.
4. Install **CBus to Home Assistant**.

Configuration fields are documented in the add-on documentation tab, which is generated from [`DOCS.md`](DOCS.md).

## Hardware

The bridge speaks the PCI serial protocol directly. It does not use Clipsal `libcbm` or C-Gate.

It works with a 5500PC serial PCI, a 5500PCU USB PCI (`cp210x` on Linux), and a 5500CN or 5500CN2 Ethernet PCI that already has an IP address. This add-on cannot give a CNI its first address.

> This software is not certified or endorsed by Clipsal or Schneider Electric. Clipsal claim that use of C-Bus with non-Clipsal hardware or software may void your warranty.

## Credits

Original `cmqttd` and libcbus work is by Michael Farrell, 2012–2020, licensed under the GNU Lesser General Public License v3.0 or later. See [COPYING.LESSER](COPYING.LESSER).

This fork adds the Home Assistant add-on, device types, command queue, MQTT discovery, and the reconnect and level-sync behaviour described above.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
