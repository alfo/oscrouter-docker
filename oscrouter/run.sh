#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Read each option, falling back to the documented default if it comes back
# empty or null. Without this, an unset option would silently produce a path of
# "/config/" and the add-on would die on a "Is a directory" error that says
# nothing about what actually went wrong.
config_or_default() {
  local value
  value=$(bashio::config "$1")
  if bashio::var.is_empty "${value}" || [ "${value}" = "null" ]; then
    echo "$2"
  else
    echo "${value}"
  fi
}

CONFIG_FILE=$(config_or_default 'config_file' 'oscrouter.osc.txt')
RECONNECT_DELAY=$(config_or_default 'reconnect_delay' '5000')
DIRECT_PORT=$(config_or_default 'direct_port' '0')

# /config is the add-on's own configuration directory, mapped read-write by
# addon_config so the routing file survives updates.
CONFIG_PATH="/config/${CONFIG_FILE}"

if [ ! -f "${CONFIG_PATH}" ]; then
  bashio::log.info "No routing file yet, creating ${CONFIG_PATH}"
  mkdir -p "$(dirname "${CONFIG_PATH}")"
  # An empty but valid configuration: default settings, nothing muted, no
  # routes. The web interface is how routes get added.
  {
    echo "Settings,,,0,,,1,0,0,0,0,0"
    echo "Mute,0,0"
  } > "${CONFIG_PATH}"
fi

bashio::log.info "Starting OSCRouter with ${CONFIG_PATH}"

if [ "${DIRECT_PORT}" -ne 0 ] 2>/dev/null; then
  bashio::log.warning "Serving the interface directly on port ${DIRECT_PORT} with no authentication"
fi

# Ingress traffic always arrives from the Supervisor proxy at 172.30.32.2, and
# nothing else is allowed to reach the interface. Home Assistant has already
# authenticated the user by that point.
exec /usr/local/bin/oscrouterd \
  --config "${CONFIG_PATH}" \
  --port 8099 \
  --bind 0.0.0.0 \
  --allow 172.30.32.2 \
  --direct-port "${DIRECT_PORT}" \
  --reconnect-delay "${RECONNECT_DELAY}"
