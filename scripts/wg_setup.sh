#!/bin/bash
set -o errexit -o pipefail -o nounset

readonly endpoint="$ARG_ENDPOINT"
readonly endpoint_public_key="$ARG_ENDPOINT_PUBLIC_KEY"
readonly ip_addr="$ARG_ASSIGNED_IP"
readonly allowed_ips="$ARG_ALLOWED_IPS"
readonly private_key="$ARG_PRIVATE_KEY"
readonly preshared_key="$ARG_PRESHARED_KEY"

readonly minport=51000
readonly maxport=51999

ifname="wg$( openssl rand -hex 4 )"
readonly ifname
port="$( shuf "--input-range=$minport-$maxport" --head-count=1 )"
readonly port

readonly private_key_path=/tmp/private.key
readonly preshared_key_path=/tmp/preshared.key

wg_tools_cleanup() {
    rm -f -- "$private_key_path"
    rm -f -- "$preshared_key_path"
}

via_wg_tools() {
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends wireguard-tools resolvconf
    trap wg_tools_cleanup EXIT

    (
        set -o errexit -o nounset -o pipefail
        umask 0077
        echo "$private_key" > "$private_key_path"
        if [ -n "$preshared_key" ]; then
            echo "$preshared_key" > "$preshared_key_path"
        fi
    )

    sudo ip link add dev "$ifname" type wireguard
    sudo ip addr add "$ip_addr" dev "$ifname"
    sudo wg set "$ifname" \
        listen-port "$port" \
        private-key "$private_key_path"

    additional_wg_args=()

    if [ -n "$preshared_key" ]; then
        additional_wg_args+=(preshared-key "${preshared_key_path}")
    fi

    sudo wg set "$ifname" \
        peer "$endpoint_public_key" \
        endpoint "$endpoint" \
        allowed-ips "$allowed_ips" \
        persistent-keepalive "25" \
        "${additional_wg_args[@]}"

    sudo ip link set "$ifname" up

    # Add routes for allowed_ips
    for i in ${allowed_ips//,/ }; do sudo ip route replace "$i" dev "$ifname"; done
    echo 'nameserver 192.168.0.2' | sudo tee -a /etc/resolv.conf
}

via_wg_tools