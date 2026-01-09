#!/bin/bash

cpu_usage() {
	read -r cpu user nice system idle iowait irq softirq steal guest < /proc/stat
	total1=$((user+nice+system+idle+iowait+irq+softirq+steal))
	idle1=$idle

	sleep 0.5

	read -r cpu user nice system idle iowait irq softirq steal guest < /proc/stat
	total2=$((user+nice+system+idle+iowait+irq+softirq+steal))
	idle2=$idle

	usage=$((100*( (total2-total1) - (idle2-idle1) ) / (total2-total1) ))
	echo $usage
}

cpu_bar() {
	usage=$1
	blocks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
	index=$((usage*7/100))
	echo -n "${blocks[$index]}"
}

eth_status() {
	local IFACE="eth0"
	[ ! -d "/sys/class/net/$IFACE" ] && echo "ETH: Disconnected!" && return

	local STATE
	STATE=$(< /sys/class/net/$IFACE/operstate)

	if [ "$STATE" = "up" ]; then
		local IP
		IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
		echo "ETH: ${IP:-unknown}"
	else
		echo "ETH: Disconnected!"
	fi
}

while true; do
	cpu=$(cpu_usage)
	bar=$(cpu_bar $cpu)
	eth=$(eth_status)
	mem_used=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {printf "%d", (total - avail)/1024}' /proc/meminfo)
	mem_total=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)

	time=$(date +"%a %b %e... %Y @ %I:%M %p")

	xsetroot -name "CPU: $bar $cpu% | $eth | $mem_used/$mem_total MB | $time"
	sleep 1
done
