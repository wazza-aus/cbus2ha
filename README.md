# Integrate Clipsal C-Bus with Home Assistant

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]
![Supports i386 Architecture][i386-shield]

This add-on bridges a Clipsal C-Bus PCI or CNI to Home Assistant over MQTT. It is a fork of [cmqttd](https://github.com/micolous/cbus) by Michael Farrell, packaged for Home Assistant.

Group addresses are dimmable lights unless you list them as something else:

- **Non-dimmable lights** are on/off only.
- **Switches** are on/off controls.
- **Binary sensors** report state and do not accept commands.
- **Ignored** addresses are not published to MQTT.

On startup the bridge connects to C-Bus, waits until MQTT is connected, then reads the live level of each lighting group and publishes that state. Wall and app changes after that are passed through as they happen.

If the MQTT broker disappears, the add-on retries for five minutes. If the broker is still down, the add-on exits so the Supervisor can start it again.

## Versions

This branch stays at 1.1.0. Home Assistant follows the branch already checked out in its copy of this repository, so an install that already follows `master` keeps 1.1.0.

`main` is the GitHub default branch and carries the current release. A new install of `https://github.com/wazza-aus/cbus2ha` follows `main`. Retiring `master` will be announced later.

`beta` is a development branch. Home Assistant offers it only when that copy is checked out on `beta`.

## Move an existing install to main

Removing this repository from the add-on store uninstalls the add-on. Leave the repository in place and point the existing copy at `main`.

1. Install the Advanced SSH & Web Terminal add-on. Set a username and password, turn protection mode off, and start it.
2. Open its terminal and run:

```bash
docker exec hassio_supervisor sh -c '
set -e
repo=
for d in /data/apps/git/* /data/addons/git/*; do
  [ -d "$d/.git" ] || continue
  url=$(git -C "$d" remote get-url origin 2>/dev/null || true)
  case "$url" in
    *github.com/wazza-aus/cbus2ha*) repo=$d; break ;;
  esac
done
[ -n "$repo" ]
cd "$repo"
git fetch --depth 1 origin main
git update-ref refs/remotes/origin/main FETCH_HEAD
git checkout -B main FETCH_HEAD
git config remote.origin.fetch "+refs/heads/main:refs/remotes/origin/main"
git rev-parse --abbrev-ref HEAD
grep "^version:" config.yaml
'
ha supervisor restart
```

The command prints `main` and `version: "1.2.0"`. After the Supervisor restarts, the add-on page offers that version. The installed add-on stays as it is until you choose the update.

Version 1.2.0 runs on 64-bit Home Assistant only. After it is installed, do not go back to 1.1.0.

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
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
