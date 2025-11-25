set -euo pipefail

WORK_DIR="/tmp/rpi-custom-build"
OUTPUT_DIR="./result"
IMAGE_URL="https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2025-11-24/2025-11-24-raspios-bookworm-armhf-lite.img.xz"

usage() {
    cat << EOF
Usage: $0 <private_key> <address> <server_pubkey> <server_endpoint> <allowed_ips> <ssh_pubkey_path>

Build a custom Raspberry Pi OS image with Wireguard pre-configured.

Arguments:
    private_key        Wireguard private key for this client
    address            Client IP address with CIDR (e.g., 10.2.2.20/24)
    server_pubkey      Wireguard server public key
    server_endpoint    Server endpoint (e.g., 91.98.84.215:51820)
    allowed_ips        Allowed IPs to route through tunnel (e.g., 10.2.2.0/24)
    ssh_pubkey_path    Path to SSH public key file

Generate Wireguard key pair:
    wg genkey | tee /dev/stderr | wg pubkey
    (First line is private key, second line is public key)

    Or with Nix:
    nix-shell -p wireguard-tools --run "wg genkey | tee /dev/stderr | wg pubkey"

Example:
    $0 "CLIENT_PRIVATE_KEY" "10.2.2.20/24" "SERVER_PUBLIC_KEY" \\
       "91.98.84.215:51820" "10.2.2.0/24" ~/.ssh/id_rsa.pub

EOF
    exit 1
}

if [[ $# -ne 6 ]]; then
    echo "Error: All 6 arguments are required"
    usage
fi

WG_PRIVATE_KEY="$1"
WG_CLIENT_ADDRESS="$2"
WG_SERVER_PUBLIC_KEY="$3"
WG_SERVER_ENDPOINT="$4"
WG_ALLOWED_IPS="$5"
SSH_PUBKEY_PATH="$6"

if [[ ! -f "$SSH_PUBKEY_PATH" ]]; then
    echo "Error: SSH public key file not found: $SSH_PUBKEY_PATH"
    exit 1
fi

SSH_PUBKEY=$(cat "$SSH_PUBKEY_PATH")
WG_PUBLIC_KEY=$(echo "$WG_PRIVATE_KEY" | wg pubkey)

echo "=== Raspberry Pi Wireguard Image Builder ==="
echo "Work directory: $WORK_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Client address: $WG_CLIENT_ADDRESS"
echo "Server endpoint: $WG_SERVER_ENDPOINT"
echo "Allowed IPs: $WG_ALLOWED_IPS"
echo "SSH public key: $SSH_PUBKEY_PATH"
echo

mkdir -p "$WORK_DIR"
mkdir -p "$OUTPUT_DIR"
cd "$WORK_DIR"

if [[ ! -f raspios.img ]]; then
    echo "Downloading Raspberry Pi OS Lite..."
    curl -L "$IMAGE_URL" -o raspios.img.xz
    echo "Extracting image..."
    xz -d raspios.img.xz
    mv *.img raspios.img 2>/dev/null || true
fi

echo "Mounting image..."
LOOP_DEVICE=$(sudo losetup -f --show -P raspios.img)
echo "Loop device: $LOOP_DEVICE"

sudo mkdir -p /mnt/rpi-boot /mnt/rpi-root
sudo mount "${LOOP_DEVICE}p1" /mnt/rpi-boot
sudo mount "${LOOP_DEVICE}p2" /mnt/rpi-root

cleanup() {
    echo "Cleaning up..."
    sudo umount /mnt/rpi-boot 2>/dev/null || true
    sudo umount /mnt/rpi-root 2>/dev/null || true
    sudo losetup -d "$LOOP_DEVICE" 2>/dev/null || true
    sudo rm -rf /mnt/rpi-boot /mnt/rpi-root
}
trap cleanup EXIT

echo "Creating Wireguard configuration..."
sudo mkdir -p /mnt/rpi-root/etc/wireguard
sudo tee /mnt/rpi-root/etc/wireguard/wg0.conf > /dev/null << EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_CLIENT_ADDRESS

[Peer]
PublicKey = $WG_SERVER_PUBLIC_KEY
Endpoint = $WG_SERVER_ENDPOINT
AllowedIPs = $WG_ALLOWED_IPS
PersistentKeepalive = 25
EOF
sudo chmod 600 /mnt/rpi-root/etc/wireguard/wg0.conf

echo "Setting up SSH access..."
sudo mkdir -p /mnt/rpi-root/root/.ssh
echo "$SSH_PUBKEY" | sudo tee /mnt/rpi-root/root/.ssh/authorized_keys > /dev/null
sudo chmod 700 /mnt/rpi-root/root/.ssh
sudo chmod 600 /mnt/rpi-root/root/.ssh/authorized_keys

echo "Creating Wireguard installation script..."
sudo tee /mnt/rpi-root/root/setup-wireguard.sh > /dev/null << 'SETUP_SCRIPT'
#!/bin/bash
set -e

echo "Installing Wireguard..."
apt-get update
apt-get install -y wireguard wireguard-tools

echo "Enabling Wireguard service..."
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo "Wireguard setup complete!"
wg show

rm /root/setup-wireguard.sh
SETUP_SCRIPT
sudo chmod +x /mnt/rpi-root/root/setup-wireguard.sh

echo "Creating first-boot service..."
sudo tee /mnt/rpi-root/etc/systemd/system/wireguard-first-boot.service > /dev/null << 'SERVICE'
[Unit]
Description=Setup Wireguard on first boot
After=network-online.target
Wants=network-online.target
Before=wg-quick@wg0.service

[Service]
Type=oneshot
ExecStart=/root/setup-wireguard.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

sudo ln -sf /etc/systemd/system/wireguard-first-boot.service \
    /mnt/rpi-root/etc/systemd/system/multi-user.target.wants/wireguard-first-boot.service

echo "Enabling SSH..."
sudo touch /mnt/rpi-boot/ssh

echo "Copying image to output directory..."
mkdir -p "$OUTPUT_DIR"
CLIENT_IP=$(echo "$WG_CLIENT_ADDRESS" | cut -d'/' -f1)
OUTPUT_IMAGE="$OUTPUT_DIR/raspios-wg-${CLIENT_IP}.img"
cp raspios.img "$OUTPUT_IMAGE"

echo "Creating configuration summary..."
cat > "$OUTPUT_DIR/wireguard-config-${CLIENT_IP}.txt" << EOF
Raspberry Pi Wireguard Configuration
====================================

Client Public Key: $WG_PUBLIC_KEY
Client Address: $WG_CLIENT_ADDRESS
Server Endpoint: $WG_SERVER_ENDPOINT
Allowed IPs: $WG_ALLOWED_IPS

Add this to your Wireguard server configuration:

[Peer]
PublicKey = $WG_PUBLIC_KEY
AllowedIPs = ${WG_CLIENT_ADDRESS%/*}/32

EOF

cat "$OUTPUT_DIR/wireguard-config-${CLIENT_IP}.txt"

echo
echo "===================================="
echo "Image customization complete!"
echo "===================================="
echo "Output image: $OUTPUT_IMAGE"
echo "Config saved: $OUTPUT_DIR/wireguard-config-${CLIENT_IP}.txt"
echo
echo "CLIENT PUBLIC KEY (add to server):"
echo "$WG_PUBLIC_KEY"
echo
echo "To flash to SD card:"
echo "  sudo dd if=$OUTPUT_IMAGE of=/dev/sdX bs=4M status=progress conv=fsync"
echo
