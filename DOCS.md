# CBus to Home Assistant

This Home Assistant add-on bridges a Clipsal CBus lighting system to Home Assistant via MQTT, enabling control and monitoring of CBus devices through the Home Assistant interface.

## Features

- **MQTT Bridge**: Connects C-Bus PCI/CNI to Home Assistant via MQTT
- **Lighting Control**: Full support for C-Bus lighting including on/off, dimming, and ramp (fade) functions
- **TCP or Serial**: Support for both network (CNI) and serial (PCI) connections
- **Auto-Discovery**: Automatic device discovery in Home Assistant via MQTT
- **Time Sync**: Optionally synchronize time with the C-Bus network
- **Customizable Labels**: Support for C-Bus Toolkit project files for friendly device names

## Configuration

### Required Settings

#### MQTT Broker
The hostname or IP address of your MQTT broker. If using the Mosquitto add-on, use `core-mosquitto`.

**Example**: `core-mosquitto` or `192.168.1.100`

#### MQTT Username
Username for MQTT authentication. Leave blank if your broker doesn't require authentication.

#### MQTT Password
Password for MQTT authentication. Leave blank if your broker doesn't require authentication.

#### C-Bus Connection Type
Select how your C-Bus system is connected:
- **tcp**: For C-Bus CNI (network connection)
- **serial**: For C-Bus PCI (USB/serial connection)

#### C-Bus Connection String
Connection details for your C-Bus interface:
- **For TCP**: IP address and port (e.g., `192.168.1.50:10001`)
- **For Serial**: Device path (e.g., `/dev/ttyUSB0`)

### Optional Settings

#### MQTT Use TLS
Enable TLS/SSL encryption for MQTT connection. Default: `false`

**Note**: When enabled without custom certificates, Python's default CA store is used.

#### MQTT Port
Custom MQTT port. Set to `0` to use defaults:
- `1883` for non-TLS connections
- `8883` for TLS connections

#### C-Bus Time Sync
Interval (in seconds) to send time synchronization packets to the C-Bus network. Set to `0` to disable. Default: `300` (5 minutes)

#### Project File Path
Path to a C-Bus Toolkit project backup file (.cbz or .xml) for custom group address labels. If not specified, generic names like "C-Bus Light 001" will be used.

**Example**: `/config/cbus/project.cbz`

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the "C-Bus to Home Assistant (cbus2ha)" add-on
3. Configure the add-on with your MQTT and C-Bus settings
4. Start the add-on
5. Check the logs to ensure successful connection

## Usage

Once configured and running, the add-on will:

1. Connect to your MQTT broker
2. Connect to your C-Bus PCI/CNI
3. Publish device discovery messages to Home Assistant
4. Create light entities for all 256 possible C-Bus group addresses (0-255)

All C-Bus lights will appear in Home Assistant as:
- **Light entities**: For full control (on/off/brightness/transitions)
- **Binary sensor entities**: For simple on/off status

### Controlling Lights

**Turn On**:
```yaml
service: light.turn_on
target:
  entity_id: light.cbus_light_001
```

**Dim to 50%**:
```yaml
service: light.turn_on
data:
  brightness: 127
target:
  entity_id: light.cbus_light_001
```

**Fade to Full Over 10 Seconds**:
```yaml
service: light.turn_on
data:
  brightness: 255
  transition: 10
target:
  entity_id: light.cbus_light_001
```

**Fade Off Over 5 Seconds**:
```yaml
service: light.turn_off
data:
  transition: 5
target:
  entity_id: light.cbus_light_001
```

## Troubleshooting

### Add-on won't start
- Check the logs for error messages
- Verify MQTT broker is running and accessible
- Verify C-Bus connection details are correct

### Can't connect to C-Bus
- **TCP**: Ensure the CNI IP address and port are correct (usually port 10001)
- **Serial**: Ensure the device path is correct and the add-on has permission to access it

### No devices appear in Home Assistant
- Check that MQTT integration is configured in Home Assistant
- Verify MQTT credentials are correct
- Check add-on logs for connection errors

### Lights don't respond
- C-Bus network may be busy - commands may need to be rate-limited
- Check C-Bus physical network connections
- Verify group addresses exist on your C-Bus network

## Technical Details

- Based on libcbus (https://github.com/micolous/cbus)
- Uses MQTT JSON schema for Home Assistant integration
- Supports all 256 C-Bus lighting group addresses (0-255)
- Implements C-Bus lighting application protocol
- Time synchronization keeps C-Bus network clock accurate

## License

This add-on uses libcbus, which is licensed under the GNU Lesser General Public License v3.0 or later.






