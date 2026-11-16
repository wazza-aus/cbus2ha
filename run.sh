#!/usr/bin/env bash
# Home Assistant Add-on entry point for cbus2ha
set -e

echo "Starting C-Bus to Home Assistant bridge..."

# Read configuration from Home Assistant
CONFIG_PATH="/data/options.json"

# Parse JSON config using jq (installed in base image)
# Note: Config is nested (mqtt, cbus, ga) based on config.yaml schema
MQTT_BROKER=$(jq -r '.mqtt.mqtt_broker // ""' $CONFIG_PATH)
MQTT_USERNAME=$(jq -r '.mqtt.mqtt_username // ""' $CONFIG_PATH)
MQTT_PASSWORD=$(jq -r '.mqtt.mqtt_password // ""' $CONFIG_PATH)
MQTT_USE_TLS=$(jq -r '.mqtt.mqtt_use_tls // false' $CONFIG_PATH)
MQTT_PORT=$(jq -r '.mqtt.mqtt_port // 0' $CONFIG_PATH)
MQTT_USE_DEFAULT=$(jq -r '.mqtt.use_mosquitto_addon // empty' $CONFIG_PATH)

# A saved broker from before the switch existed must keep working. The
# switch is only written once; after that, the switch is what is used.
mqtt_settings_are_custom() {
    if [ -n "${MQTT_USERNAME}" ]; then
        return 0
    fi
    if [ -n "${MQTT_BROKER}" ] && [ "${MQTT_BROKER}" != "core-mosquitto" ]; then
        return 0
    fi
    if [ "${MQTT_USE_TLS}" = "true" ]; then
        return 0
    fi
    if [ -n "${MQTT_PORT}" ] && [ "${MQTT_PORT}" != "0" ] && [ "${MQTT_PORT}" != "null" ]; then
        return 0
    fi
    return 1
}

save_mosquitto_switch() {
    local value="$1"
    local payload
    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        return 1
    fi
    payload=$(jq --argjson value "${value}" '{options: (.mqtt.use_mosquitto_addon = $value)}' "$CONFIG_PATH")
    curl -fsS --max-time 10 -X POST \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${payload}" \
        http://supervisor/addons/self/options >/dev/null
}

if [ ! -f /data/.mqtt_ui_migrated ]; then
    if mqtt_settings_are_custom; then
        echo "Saved MQTT broker settings found, so Use the Mosquitto add-on is off."
        MQTT_USE_DEFAULT=false
        if save_mosquitto_switch false; then
            touch /data/.mqtt_ui_migrated
        else
            echo "Could not save that switch position. It will be tried again on the next start."
        fi
    else
        MQTT_USE_DEFAULT=true
        touch /data/.mqtt_ui_migrated
    fi
fi

read_mosquitto_service() {
    local info host
    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        return 1
    fi
    info=$(curl -fsS --max-time 5 \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        http://supervisor/services/mqtt) || return 1
    host=$(printf '%s' "${info}" | jq -r '.data.host // empty')
    if [ -z "${host}" ]; then
        return 1
    fi
    echo "Using the Mosquitto add-on"
    MQTT_BROKER="${host}"
    MQTT_PORT=$(printf '%s' "${info}" | jq -r '.data.port // 1883')
    MQTT_USERNAME=$(printf '%s' "${info}" | jq -r '.data.username // empty')
    MQTT_PASSWORD=$(printf '%s' "${info}" | jq -r '.data.password // empty')
    MQTT_USE_TLS=$(printf '%s' "${info}" | jq -r '.data.ssl // false')
}

if [ "${MQTT_USE_DEFAULT}" != "false" ]; then
    if ! read_mosquitto_service; then
        echo "Could not read the Mosquitto add-on account. Start the Mosquitto add-on, or turn off Use the Mosquitto add-on and enter a broker."
        exit 1
    fi
elif [ -z "${MQTT_BROKER}" ]; then
    echo "Use the Mosquitto add-on is off, and no broker address is set."
    exit 1
fi
CBUS_CONNECTION_TYPE=$(jq -r '.cbus.cbus_connection_type // "tcp"' $CONFIG_PATH)
CBUS_CONNECTION_STRING=$(jq -r '.cbus.cbus_connection_string // "192.168.1.50:10001"' $CONFIG_PATH)
CBUS_TIMESYNC=$(jq -r '.cbus.cbus_timesync // 300' $CONFIG_PATH)
PROJECT_FILE_PATH=$(jq -r '.cbus.project_file_path // ""' $CONFIG_PATH)
NON_DIMMABLE_LIGHTS=$(jq -r '.ga.non_dimmable_lights // ""' $CONFIG_PATH)
SWITCHES=$(jq -r '.ga.switches // ""' $CONFIG_PATH)
BINARY_SENSORS=$(jq -r '.ga.binary_sensors // ""' $CONFIG_PATH)
IGNORE=$(jq -r '.ga.ignore // ""' $CONFIG_PATH)

echo "MQTT Broker: ${MQTT_BROKER}"
echo "C-Bus Connection Type: ${CBUS_CONNECTION_TYPE}"
echo "C-Bus Connection: ${CBUS_CONNECTION_STRING}"

# Create MQTT auth file if credentials provided
MQTT_AUTH_FILE="/tmp/mqtt_auth.txt"
if [ -n "${MQTT_USERNAME}" ] && [ -n "${MQTT_PASSWORD}" ]; then
    echo "Creating MQTT authentication file..."
    echo "${MQTT_USERNAME}" > "${MQTT_AUTH_FILE}"
    echo "${MQTT_PASSWORD}" >> "${MQTT_AUTH_FILE}"
fi

# Build command arguments
CMQTTD_ARGS="--broker-address ${MQTT_BROKER}"

# MQTT Port
if [ "${MQTT_PORT}" -gt 0 ]; then
    CMQTTD_ARGS="${CMQTTD_ARGS} --broker-port ${MQTT_PORT}"
fi

# MQTT TLS
if [ "${MQTT_USE_TLS}" = "true" ]; then
    echo "TLS enabled for MQTT connection"
else
    echo "TLS disabled for MQTT connection (insecure)"
    CMQTTD_ARGS="${CMQTTD_ARGS} --broker-disable-tls"
fi

# MQTT Authentication
if [ -e "${MQTT_AUTH_FILE}" ]; then
    echo "Using MQTT authentication"
    CMQTTD_ARGS="${CMQTTD_ARGS} --broker-auth ${MQTT_AUTH_FILE}"
else
    echo "WARNING: No MQTT authentication configured"
fi

# C-Bus Connection (TCP or Serial)
if [ "${CBUS_CONNECTION_TYPE}" = "tcp" ]; then
    echo "Using TCP connection to C-Bus CNI/PCI"
    CMQTTD_ARGS="${CMQTTD_ARGS} --tcp ${CBUS_CONNECTION_STRING}"
elif [ "${CBUS_CONNECTION_TYPE}" = "serial" ]; then
    echo "Using serial connection to C-Bus PCI"
    CMQTTD_ARGS="${CMQTTD_ARGS} --serial ${CBUS_CONNECTION_STRING}"
else
    echo "ERROR: Invalid C-Bus connection type: ${CBUS_CONNECTION_TYPE}"
    exit 1
fi

# Time synchronization
if [ "${CBUS_TIMESYNC}" -gt 0 ]; then
    echo "Time sync interval: ${CBUS_TIMESYNC} seconds"
    CMQTTD_ARGS="${CMQTTD_ARGS} --timesync ${CBUS_TIMESYNC}"
else
    echo "Time synchronization disabled"
    CMQTTD_ARGS="${CMQTTD_ARGS} --timesync 0"
fi

# Project file (optional)
if [ -n "${PROJECT_FILE_PATH}" ] && [ -e "${PROJECT_FILE_PATH}" ]; then
    echo "Using C-Bus project file: ${PROJECT_FILE_PATH}"
    CMQTTD_ARGS="${CMQTTD_ARGS} --project-file ${PROJECT_FILE_PATH}"
else
    echo "No project file configured, using generated labels"
fi

# Device type configurations
if [ -n "${NON_DIMMABLE_LIGHTS}" ]; then
    echo "Non-dimmable lights: ${NON_DIMMABLE_LIGHTS}"
    CMQTTD_ARGS="${CMQTTD_ARGS} --non-dimmable-lights ${NON_DIMMABLE_LIGHTS}"
fi

if [ -n "${SWITCHES}" ]; then
    echo "Switches: ${SWITCHES}"
    CMQTTD_ARGS="${CMQTTD_ARGS} --switches ${SWITCHES}"
fi

if [ -n "${BINARY_SENSORS}" ]; then
    echo "Binary sensors: ${BINARY_SENSORS}"
    CMQTTD_ARGS="${CMQTTD_ARGS} --binary-sensors ${BINARY_SENSORS}"
fi

if [ -n "${IGNORE}" ]; then
    echo "Ignored devices: ${IGNORE}"
    CMQTTD_ARGS="${CMQTTD_ARGS} --ignore ${IGNORE}"
fi

# Display timezone info
echo "Timezone: ${TZ:-UTC}"
echo "Current time: $(date -R)"

# Log the final command
echo "Starting cmqttd with arguments: ${CMQTTD_ARGS}"

# Execute cmqttd
exec python3 -m cbus.daemon.cmqttd ${CMQTTD_ARGS}

