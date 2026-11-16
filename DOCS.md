# CBus to Home Assistant

This add-on bridges a Clipsal C-Bus lighting system to Home Assistant via MQTT.

## What it does

1. Connects to your C-Bus PCI or CNI.
2. Connects to your MQTT broker, retrying for up to five minutes if the broker is still starting.
3. Reads the current level of each lighting group from C-Bus and publishes that state.
4. Publishes MQTT discovery so Home Assistant creates the entities below.
5. Forwards later C-Bus changes to Home Assistant, and Home Assistant commands back to C-Bus.

If the broker connection drops after startup, the add-on retries for five minutes. It does not publish discovery again, and it does not re-read every level, unless a C-Bus change happened while the broker was down. Publishing discovery on every reconnect was reloading entities and making HomeKit announce a door as unlocked, then locked. If the broker does not return, the add-on exits and the Supervisor starts it again. The new start reads levels from C-Bus once MQTT is connected.

The first start that still finds the older per-entity discovery moves those entities onto the one C-Bus device, then deletes the old messages. That move is remembered only after the delete. Later starts leave discovery where it is. If the old messages are in the broker again, the next start moves them and deletes them again.

## Device types

Every group address from 0 to 255 is a **dimmable light** unless you list it in one of the fields below. Home Assistant creates all of them under a single C-Bus device.

| Field | Result in Home Assistant |
| --- | --- |
| Non-dimmable lights | On/off light. Brightness and fade commands are ignored. |
| Switches | Switch. On or off only. |
| Binary sensors | Read-only sensor. Commands are ignored. |
| Ignored devices | Not discovered and not subscribed. |

Comma-separate the group addresses, for example `26,65,81`.

## Configuration

### MQTT

Leave the broker address, username, and password blank to use the Mosquitto add-on. Leave **Use TLS Encryption** off and **MQTT Port** at `0`. The add-on then uses the Mosquitto account Home Assistant provides, and it picks up a new password when that add-on changes it.

For a different broker, enter its hostname or IP address. Add a username and password only when that broker requires them. Turn on TLS to encrypt that connection. Set the port when it is not 1883, or 8883 with TLS on. With TLS on and no custom certificates, Python's default CA store is used.

An install that already has a broker address, username, password, TLS, or a custom port keeps those values and continues to use them.

### C-Bus Connection Type

- **tcp** for a CNI or a networked PCI
- **serial** for a USB or serial PCI

### C-Bus Connection String

- TCP: `192.168.1.50:10001`
- Serial: `/dev/ttyUSB0`

### C-Bus Time Sync

How often, in seconds, to send the clock to the C-Bus network. `0` disables it. Default: `300`.

### Project File Path

Optional path to a C-Bus Toolkit backup (`.cbz` or `.xml`) used for entity names. Without it, names look like `C-Bus Light 001`.

Example: `/config/cbus/project.cbz`

## Controlling lights

These examples use group address 1, discovered as `light.cbus_light_001`.

**Turn on**

```yaml
action: light.turn_on
target:
  entity_id: light.cbus_light_001
```

**Dim to 50%**

```yaml
action: light.turn_on
target:
  entity_id: light.cbus_light_001
data:
  brightness: 127
```

**Fade to full over 10 seconds**

```yaml
action: light.turn_on
target:
  entity_id: light.cbus_light_001
data:
  brightness: 255
  transition: 10
```

**Fade off over 5 seconds**

```yaml
action: light.turn_off
target:
  entity_id: light.cbus_light_001
data:
  transition: 5
```

Non-dimmable lights and switches ignore brightness and transition.

## Troubleshooting

### The add-on does not stay running

Check the log. A C-Bus interface that is still booting, or an MQTT broker that stays down for more than five minutes, causes the add-on to exit. The Supervisor starts it again. Confirm the broker is up and the C-Bus address is reachable, then start the add-on once more.

### Cannot connect to C-Bus

- **TCP:** the CNI address and port are usually port `10001`. The CNI must already have an IP address.
- **Serial:** the device path must exist, and the add-on must be allowed to use it.

### Nothing appears in Home Assistant

- The MQTT integration must be connected to the same broker.
- With the MQTT fields left blank, the Mosquitto add-on must be running. Home Assistant’s MQTT integration should use that same add-on.
- With a broker address filled in, the username and password must match that broker.
- Addresses listed under **Ignored devices** are not discovered.

### A light or switch did not follow a command

Commands are queued and retried after the PCI confirms them. If the log shows the confirmation timing out, the C-Bus network or the cabling to the PCI is the place to look.

## Updates

Home Assistant installs this add-on from the `master` branch. An update appears when the `version` in that branch's `config.yaml` is newer than the version you have installed. There is no version list to pick from.

## License

The add-on uses libcbus, licensed under the GNU Lesser General Public License v3.0 or later.
