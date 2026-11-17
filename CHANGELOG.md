# Changelog

## 1.2.0

- Blank MQTT settings now read the Mosquitto add-on account from the Supervisor reply. Version 1.1.1 looked in the wrong place and stopped before connecting.
- A later MQTT reconnect does not publish discovery again or re-read every C-Bus level. Doing that on each reconnect was reloading the door in Home Assistant, so HomeKit announced it unlocked and then locked. Levels are read again only if a C-Bus change was missed while MQTT was down.
- The move onto one C-Bus device is remembered only after the old per-entity discovery messages are deleted. A restart does not write those old messages again. If they are still in the broker, the next start moves them and deletes them before it is remembered as finished.
- The add-on is built for 64-bit Home Assistant only (`aarch64` and `amd64`). `armhf`, `armv7`, and `i386` are no longer available.
- After this version is installed, do not go back to 1.1.0. That writes the old discovery messages again, and Home Assistant then has two copies of every light.
- Version 1.2.0 is published on the `main` branch, which is the GitHub default. The `master` branch stays at 1.1.0, so an install that already follows `master` is unchanged. Retiring `master` will be announced later.

## 1.1.1

- Switches now publish `{"state":"ON"}` and `{"state":"OFF"}`, matching the JSON discovery Home Assistant was already using. Switch state updates in Home Assistant after a command.
- Lights no longer send the old `brightness` true/false flag. Dimmable lights report a brightness color mode, and on/off lights report on/off.
- Every group address is announced under one C-Bus device. Existing entity IDs are kept. The discovery message names cbus2ha and links to the project.
- The add-on image is Alpine 3.24. It is built for 64-bit Home Assistant only (`aarch64` and `amd64`). `armhf`, `armv7`, and `i386` are no longer available.
- Leave the MQTT broker, username, and password blank to use the Mosquitto add-on. An install that already has a broker address, login, TLS, or a custom port keeps those settings.
- The Alpine 3.24 image installs setuptools, which that Python no longer includes, so the add-on can build.

## 1.1.0

- After a restart, the add-on waits until MQTT is connected, then reads the live level of each lighting group from C-Bus and publishes that state.
- If the C-Bus interface is not reachable when the add-on starts, it keeps trying instead of failing the start.
- If the MQTT broker drops out, the add-on retries for five minutes and then exits so the Supervisor can start it again.
- The documentation describes the current add-on behaviour, and that Home Assistant installs from `master` using the version in `config.yaml`.

## 1.0.3

- Home Assistant add-on for a Clipsal C-Bus PCI or CNI, using MQTT.
- Group addresses are dimmable lights unless listed as non-dimmable, switch, binary sensor, or ignore.
- Commands are queued, confirmed by the PCI, and retried.
