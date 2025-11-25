#!/usr/bin/env bash
# Home Assistant Add-on entry point for cbus2ha
set -e

echo "Starting C-Bus to Home Assistant bridge..."

# Read configuration from Home Assistant
CONFIG_PATH="/data/options.json"

# Parse JSON config using jq (installed in base image)
MQTT_BROKER=$(jq -r '.mqtt_broker // "core-mosquitto"' $CONFIG_PATH)
MQTT_USERNAME=$(jq -r '.mqtt_username // ""' $CONFIG_PATH)
MQTT_PASSWORD=$(jq -r '.mqtt_password // ""' $CONFIG_PATH)
CBUS_CONNECTION_TYPE=$(jq -r '.cbus_connection_type // "tcp"' $CONFIG_PATH)
CBUS_CONNECTION_STRING=$(jq -r '.cbus_connection_string // "192.168.1.50:10001"' $CONFIG_PATH)
MQTT_USE_TLS=$(jq -r '.mqtt_use_tls // false' $CONFIG_PATH)
MQTT_PORT=$(jq -r '.mqtt_port // 0' $CONFIG_PATH)
CBUS_TIMESYNC=$(jq -r '.cbus_timesync // 300' $CONFIG_PATH)
PROJECT_FILE_PATH=$(jq -r '.project_file_path // ""' $CONFIG_PATH)
NON_DIMMABLE_LIGHTS=$(jq -r '.non_dimmable_lights // ""' $CONFIG_PATH)
SWITCHES=$(jq -r '.switches // ""' $CONFIG_PATH)
BINARY_SENSORS=$(jq -r '.binary_sensors // ""' $CONFIG_PATH)
IGNORE=$(jq -r '.ignore // ""' $CONFIG_PATH)

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

