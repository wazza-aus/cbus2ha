#!/usr/bin/env bash
# Home Assistant Add-on entry point for cbus2ha
set -e

# s6 starts this script without the container environment. Load it once so
# SUPERVISOR_TOKEN and TZ are visible.
if [ -z "${SUPERVISOR_TOKEN:-}${HASSIO_TOKEN:-}" ] \
    && [ -z "${CBUS2HA_ENV_LOADED:-}" ] \
    && [ -x /command/with-contenv ]; then
    export CBUS2HA_ENV_LOADED=1
    exec /command/with-contenv bash "$0" "$@"
fi

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

# Blank fields mean the Mosquitto add-on. A saved login, another address,
# TLS, or a custom port is used as entered.
mqtt_settings_are_blank() {
    if [ -n "${MQTT_USERNAME}" ] || [ -n "${MQTT_PASSWORD}" ]; then
        return 1
    fi
    if [ -n "${MQTT_BROKER}" ] && [ "${MQTT_BROKER}" != "core-mosquitto" ]; then
        return 1
    fi
    if [ "${MQTT_USE_TLS}" = "true" ]; then
        return 1
    fi
    if [ -n "${MQTT_PORT}" ] && [ "${MQTT_PORT}" != "0" ] && [ "${MQTT_PORT}" != "null" ]; then
        return 1
    fi
    return 0
}

supervisor_token() {
    local token="${SUPERVISOR_TOKEN:-${HASSIO_TOKEN:-}}"
    if [ -z "${token}" ] && [ -r /run/s6/container_environment/SUPERVISOR_TOKEN ]; then
        token=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN)
    fi
    if [ -z "${token}" ] && [ -r /run/s6/container_environment/HASSIO_TOKEN ]; then
        token=$(cat /run/s6/container_environment/HASSIO_TOKEN)
    fi
    printf '%s' "${token}"
}

read_mosquitto_service() {
    local info host result message token
    token=$(supervisor_token)
    if [ -z "${token}" ]; then
        echo "Supervisor did not provide an API token."
        return 1
    fi
    # The reply is either {"result":"ok","data":{...}} or the fields themselves.
    if ! info=$(curl -fsS --max-time 5 \
        -H "Authorization: Bearer ${token}" \
        http://supervisor/services/mqtt); then
        echo "Could not reach the Supervisor at http://supervisor/services/mqtt."
        if ! info=$(curl -fsS --max-time 5 \
            -H "Authorization: Bearer ${token}" \
            http://172.30.32.2/services/mqtt); then
            echo "Could not reach the Supervisor at 172.30.32.2 either."
            return 1
        fi
    fi
    result=$(printf '%s' "${info}" | jq -r '.result // "ok"')
    if [ "${result}" = "error" ]; then
        message=$(printf '%s' "${info}" | jq -r '.message // "unknown error"')
        echo "Supervisor MQTT service error: ${message}"
        return 1
    fi
    host=$(printf '%s' "${info}" | jq -r '.data.host // .host // empty')
    if [ -z "${host}" ]; then
        echo "Supervisor MQTT service did not include a broker address."
        return 1
    fi
    echo "Using the Mosquitto add-on"
    MQTT_BROKER="${host}"
    MQTT_PORT=$(printf '%s' "${info}" | jq -r '.data.port // .port // 1883')
    MQTT_USERNAME=$(printf '%s' "${info}" | jq -r '.data.username // .username // empty')
    MQTT_PASSWORD=$(printf '%s' "${info}" | jq -r '.data.password // .password // empty')
    MQTT_USE_TLS=$(printf '%s' "${info}" | jq -r '.data.ssl // .ssl // false')
}

if mqtt_settings_are_blank; then
    if ! read_mosquitto_service; then
        echo "Could not read the Mosquitto add-on account. Start the Mosquitto add-on, or enter a broker address."
        exit 1
    fi
elif [ -z "${MQTT_BROKER}" ]; then
    echo "MQTT username or password is set, but the broker address is blank."
    exit 1
else
    echo "Using the configured MQTT broker"
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

