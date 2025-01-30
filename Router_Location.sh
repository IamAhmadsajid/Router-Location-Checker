#!/bin/bash

# Developed by: 
# Ahmad(027)
# Abdul Mihad Amir(004)
# Faheem Azam(021)
# Class: Section A - DFCS

# Please ensure to have Wireless Interfact before running
# the code 

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

# Check for required tools
if ! command -v tshark &>/dev/null || ! command -v ip &>/dev/null; then
  echo "Required tools are missing. Install tshark and iproute2:"
  echo "sudo apt install tshark iproute2"
  exit 1
fi

# Get router's IP address
ROUTER_IP=$(ip route | grep default | awk '{print $3}')
if [ -z "$ROUTER_IP" ]; then
  echo "Could not determine the router's IP address."
  exit 1
fi
echo "Router IP: $ROUTER_IP"

# Get router's MAC address
ROUTER_MAC=$(arp -n | grep "$ROUTER_IP" | awk '{print $3}')
if [ -z "$ROUTER_MAC" ]; then
  echo "Could not determine the router's MAC address."
  exit 1
fi
echo "Router MAC Address: $ROUTER_MAC"

# Identify the wireless interface connected to the router
WIRELESS_INTERFACE=$(ip link show | grep -oP "^\d+: \K\w+(?=:.*state UP)")
if [ -z "$WIRELESS_INTERFACE" ]; then
  echo "No active wireless interface found. Check your Wi-Fi adapter."
  exit 1
fi
echo "Using wireless interface: $WIRELESS_INTERFACE"

# Start capturing packets from the router's MAC address
echo -e "\nTracking signal strength of packets from the router..."
echo "Move around the room. Stronger signal (closer to 0 dBm) indicates proximity."
echo "Press CTRL+C to stop."
echo -e "Signal Strength\tVisual Indicator\n"

tshark -i "$WIRELESS_INTERFACE" -f "ether src $ROUTER_MAC" -T fields -e radiotap.dbm_antsignal |
while read -r SIGNAL_STRENGTH; do
  if [[ -n "$SIGNAL_STRENGTH" ]]; then
    # Convert RSSI to a visual indicator (e.g., bar strength)
    BARS=$(( (100 + SIGNAL_STRENGTH) / 10 ))  # Normalize signal strength
    VISUAL=$(printf "%${BARS}s" | tr ' ' '#')
    echo -e "$SIGNAL_STRENGTH dBm\t[ $VISUAL ]"
  fi
done

