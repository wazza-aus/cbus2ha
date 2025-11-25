# C-Bus to Home Assistant Add-on Installation

This directory contains a Home Assistant add-on that bridges Clipsal C-Bus lighting systems to Home Assistant via MQTT.

## Files Overview

Home Assistant add-on files:
- **config.yaml** - Add-on configuration and schema
- **run.sh** - Entry point script (reads HA config and starts cmqttd)
- **Dockerfile.addon** - Home Assistant add-on compatible Dockerfile
- **build.yaml** - Multi-architecture build configuration
- **DOCS.md** - Add-on documentation (shown in Home Assistant UI)
- **icon.png** - Add-on icon (create one if desired)

Original project files (unchanged):
- **cbus/** - Python library for C-Bus protocol
- **Dockerfile** - Original Docker setup
- **entrypoint-cmqttd.sh** - Original Docker entrypoint

## Installation Methods

### Method 1: Local Add-on (For Testing)

1. Copy this entire directory to your Home Assistant installation:
   ```bash
   scp -r /path/to/cbus username@homeassistant:/addons/cbus2ha/
   ```

2. In Home Assistant:
   - Go to **Settings** → **Add-ons** → **Add-on Store**
   - Click the three dots (⋮) in the top right
   - Select **Repositories**
   - Add the local path: `/addons`
   - The add-on should now appear in the store

3. Install and configure the add-on

### Method 2: GitHub Repository (Recommended)

1. Create a GitHub repository with this add-on

2. Repository structure:
   ```
   your-repo/
   ├── cbus2ha/
   │   ├── config.yaml
   │   ├── run.sh
   │   ├── Dockerfile.addon (rename to Dockerfile)
   │   ├── build.yaml
   │   ├── DOCS.md
   │   ├── icon.png
   │   └── cbus/ (entire cbus directory)
   └── repository.yaml
   ```

3. Create `repository.yaml` in the root:
   ```yaml
   name: C-Bus Home Assistant Add-ons
   url: https://github.com/YOUR_USERNAME/YOUR_REPO
   maintainer: Your Name
   ```

4. In Home Assistant:
   - Go to **Settings** → **Add-ons** → **Add-on Store**
   - Click the three dots (⋮) in the top right
   - Select **Repositories**
   - Add: `https://github.com/YOUR_USERNAME/YOUR_REPO`
   - Click **Add**

5. Find "C-Bus to Home Assistant (cbus2ha)" in the add-on store and install

## Building the Add-on for Home Assistant

If building locally for testing:

```bash
# From this directory
docker build -f Dockerfile.addon -t local/cbus2ha .
```

For Home Assistant add-on repository, the build happens automatically via GitHub Actions (if configured).

## Configuration Example

After installation, configure the add-on with your settings:

### For TCP Connection (CNI):
```yaml
mqtt_broker: "core-mosquitto"
mqtt_username: "homeassistant"
mqtt_password: "your_password_here"
cbus_connection_type: "tcp"
cbus_connection_string: "192.168.1.50:10001"
mqtt_use_tls: false
mqtt_port: 0
cbus_timesync: 300
```

### For Serial Connection (PCI):
```yaml
mqtt_broker: "core-mosquitto"
mqtt_username: "homeassistant"
mqtt_password: "your_password_here"
cbus_connection_type: "serial"
cbus_connection_string: "/dev/ttyUSB0"
mqtt_use_tls: false
mqtt_port: 0
cbus_timesync: 300
```

## Troubleshooting

### Add-on won't start

Check the logs:
- **Settings** → **Add-ons** → **C-Bus to Home Assistant** → **Log** tab

Common issues:
- Incorrect MQTT credentials
- Wrong C-Bus IP address or port
- Serial device not accessible (need to add UART access in add-on config)

### Serial Device Access

For serial connections, you may need to:
1. Ensure the USB device is passed through to Home Assistant
2. Check device permissions
3. Verify the correct device path (run `ls /dev/tty*` in SSH)

### MQTT Connection Issues

- Verify the Mosquitto add-on is installed and running
- Check MQTT username/password match your broker configuration
- If using external MQTT broker, ensure it's accessible from Home Assistant

## Development and Testing

To test changes without affecting your production system:

1. The device name has been changed to "cbus2ha" to avoid conflicts
2. This creates separate entities in Home Assistant
3. You can run both the original and test versions simultaneously

## Next Steps

After installation:
1. Check logs to verify connection to MQTT and C-Bus
2. Go to **Settings** → **Devices & Services** to see auto-discovered lights
3. Test controlling a light
4. Optionally add a C-Bus Toolkit project file for custom labels

## Credits

This addon is based on [micolous/cbus](https://github.com/micolous/cbus), a Python library for interacting with Clipsal C-Bus systems.

- **Original Author**: Michael Farrell (micolous)
- **Original Repository**: https://github.com/micolous/cbus
- **License**: GNU Lesser General Public License v3.0 or later (LGPL-3.0+)

### Enhancements in This Fork

This fork includes significant modifications to the original `cmqttd` daemon:

- **Home Assistant Addon Integration**: Complete addon packaging with organized configuration UI
- **Device Type Support**: Extended support for switches, binary sensors, and non-dimmable lights
- **Reliable Command Queue**: Queue system with confirmation matching, retries, and state persistence
- **Home Assistant 2025.3+ Compatibility**: Color mode support and improved MQTT discovery
- **Enhanced State Management**: Queue-based updates ensure UI accuracy
- **Improved Logging**: Comprehensive queue system visibility

## Support

- Original project: https://github.com/micolous/cbus
- Issues and questions: See project documentation or open an issue in this repository

## License

This project is licensed under the GNU Lesser General Public License v3.0 or later (LGPL-3.0+).
All modifications maintain the original license. See [COPYING.LESSER](../COPYING.LESSER) for details.






