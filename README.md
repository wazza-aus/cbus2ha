# Integrate Clipsal CBUS with Home Assistant

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]
![Supports i386 Architecture][i386-shield]

## Credits

This is a fork of cmqttd project by [micolous/cbus](https://github.com/micolous/cbus) with significant modifications for Home Assistant integration.

### Original Work
- **Author**: Michael Farrell (micolous)
- **Original Repository**: https://github.com/micolous/cbus
- **License**: GNU Lesser General Public License v3.0 or later (LGPL-3.0+)
- **Copyright**: 2012-2020 Michael Farrell

### Modifications in This Fork

This fork includes extensive enhancements for Home Assistant:

- **Home Assistant Addon**: Complete addon packaging with configuration UI
- **Enhanced Device Types**: Support for switches, binary sensors, and non-dimmable lights
- **Queue System**: Reliable command delivery with confirmation matching and retry logic
- **Improved MQTT Discovery**: Better state management and Home Assistant 2025.3+ compatibility
- **Color Mode Support**: Proper `color_mode` implementation for dimmable and non-dimmable lights
- **Ramp-Down Fix**: Fixed transition time handling for lights ramping to off
- **Enhanced Logging**: Comprehensive queue system logging for debugging

### License

This project is licensed under the GNU Lesser General Public License v3.0 or later (LGPL-3.0+).
See [COPYING.LESSER](COPYING.LESSER) for details.

All modifications maintain the original LGPL-3.0+ license. Original copyright notices are preserved.

> **Note:** This software is not certified or endorsed by Clipsal or Schneider
> Electric. Clipsal claim that use of C-Bus with non-Clipsal hardware or
> software may void your warranty.

More information about the project is available on
[the libcbus ReadTheDocs site][rtd], and in the `docs` directory of the source
repository.

## About the cmqttd project: original notes from micolous.

Talks to Clipsal CBus using Python 3.7+.

This is a reimplementation of the PCI serial protocol _from scratch_. This is
done using a combination [Clipsal's _Open C-Bus_ documentation][clipsal-docs]
and reverse engineering (to fill in the gaps).

Unlike some contemporary alternatives, it does **not** use the `libcbm`
library/DLL from Clipsal, or C-Gate, which have serious problems:

* The `libcbm` module is written in C, and does not support `x86_64` or
  comparatively-modern ARM architectures (such as that used in the Raspberry
  Pi).

  `libcbm` was previously only available as a static library for `x86_32` Linux
  and Windows systems. [Source is available][libcbm-src] under the Boost
  license, but this was last updated in 2009.

* C-Gate requires an OS and architecture specific closed source serial
  library (SerialIO), the Java runtime, and itself has various licensing
  restrictions.

Because this is a pure-Python implementation, it should run on any Python
supported platform. It has been primarily developed on Linux on `armhf`,
`x86_32` and `x86_64` and macOS on `x86_64`.

At a high level, this project includes `cmqttd`, a daemon to bridge a C-Bus PCI
to an MQTT Broker. `cmqttd` supports Home Assistant's
[MQTT Light model][ha-mqtt] and [MQTT topic auto-discovery][ha-auto].

_Integration with Hass.io is still a work in progress._

## Hardware interface support

This should work with the following C-Bus PC Interfaces (PCIs):

* [5500PC Serial PCI][5500PC]

* [5500PCU USB PCI][5500PCU]

  On Linux, this requires v2.6.25 or later kernel, with the `cp210x` module.

* [5500CN Ethernet PCI][5500CN] (and likely _also_ [5500CN2][])

  This software _does not_ support configuring the Ethernet PCI for the first
  time. It must already have an IP address on your network.

## Recent updates (2020-02-22)

This project has recently completed a migration to Python 3.7.

Most things should work, but I'm still going through updating all the documentation properly.

There are many backward-incompatible changes:

* This _only_ supports Python 3.7 and later.

* Python 2.x support _has been entirely removed_, [as Python 2 has been sunset as of 2020][py2].

  Python 3.6 and earlier support is not a goal. We want to use new language features!

* D-Bus is no longer used by this project:

  * `cmqttd` (C-Bus to MQTT bridge) replaces `cdbusd` (C-Bus to D-Bus bridge).

  * `dbuspcid` (virtual PCI to D-Bus bridge) has been removed. It has no replacement.

* `sage` (libcbus' web interface) and `staged` (scene management system) have been removed.
  `cmqttd` supports [Home Assistant's MQTT Discovery schema][ha-auto].

  This allows `libcbus` to reduce its scope significantly -- Home Assistant can interface with much
  more hardware than C-Bus, and has a large community around it.

* This no longer uses Twisted -- `asyncio` (in the standard library) is used instead.

Many APIs have changed due to refactoring, and is subject to further change without notice. The
most stable API is via MQTT (`cmqttd`).

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg