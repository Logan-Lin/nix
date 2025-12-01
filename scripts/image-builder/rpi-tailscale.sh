set -euo pipefail

ORIGINAL_DIR="$PWD"
WORK_DIR="/tmp/rpi-custom-build"
OUTPUT_DIR="$ORIGINAL_DIR/result"
IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2025-11-24/2025-11-24-raspios-trixie-arm64-lite.img.xz"

usage() {
    cat << EOF
Usage: $0 <auth_key> <ssh_pubkey_path> [options]

Build a custom Raspberry Pi OS image with Tailscale pre-configured.

Required:
    auth_key        Tailscale auth key for automatic node registration
    ssh_pubkey_path Path to SSH public key file

Options:
    --subnet-routes <routes>  Advertise subnet routes (comma-separated, e.g., "192.168.1.0/24,10.0.0.0/8")
    --exit-node               Advertise as exit node
    --hostname <name>         Custom hostname (default: rpi-ts-<random>)

Generate auth key:
    Go to https://login.tailscale.com/admin/settings/keys
    Create an auth key (reusable recommended for testing)

Example:
    $0 "tskey-auth-xxxxx" ~/.ssh/id_rsa.pub

    $0 "tskey-auth-xxxxx" ~/.ssh/id_rsa.pub --subnet-routes "192.168.1.0/24" --exit-node

    $0 "tskey-auth-xxxxx" ~/.ssh/id_rsa.pub --hostname "my-pi" --exit-node

EOF
    exit 1
}

if [[ $# -lt 2 ]]; then
    echo "Error: At least 2 required arguments"
    usage
fi

TS_AUTH_KEY="$1"
SSH_PUBKEY_PATH="$2"
shift 2

SUBNET_ROUTES=""
EXIT_NODE=""
HOSTNAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --subnet-routes)
            SUBNET_ROUTES="$2"
            shift 2
            ;;
        --exit-node)
            EXIT_NODE="1"
            shift
            ;;
        --hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown option $1"
            usage
            ;;
    esac
done

if [[ ! -f "$SSH_PUBKEY_PATH" ]]; then
    echo "Error: SSH public key file not found: $SSH_PUBKEY_PATH"
    exit 1
fi

SSH_PUBKEY=$(cat "$SSH_PUBKEY_PATH")

if [[ -z "$HOSTNAME" ]]; then
    HOSTNAME="rpi-ts-$(head -c 4 /dev/urandom | xxd -p)"
fi

echo "=== Raspberry Pi Tailscale Image Builder ==="
echo "Work directory: $WORK_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Hostname: $HOSTNAME"
echo "Subnet routes: ${SUBNET_ROUTES:-none}"
echo "Exit node: ${EXIT_NODE:-no}"
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

echo "Setting up SSH access..."
sudo mkdir -p /mnt/rpi-root/root/.ssh
echo "$SSH_PUBKEY" | sudo tee /mnt/rpi-root/root/.ssh/authorized_keys > /dev/null
sudo chmod 700 /mnt/rpi-root/root/.ssh
sudo chmod 600 /mnt/rpi-root/root/.ssh/authorized_keys

echo "Setting hostname..."
echo "$HOSTNAME" | sudo tee /mnt/rpi-root/etc/hostname > /dev/null
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/" /mnt/rpi-root/etc/hosts

TS_UP_ARGS="--authkey=$TS_AUTH_KEY"
NEED_IP_FORWARD=""

if [[ -n "$SUBNET_ROUTES" ]]; then
    TS_UP_ARGS="$TS_UP_ARGS --advertise-routes=$SUBNET_ROUTES"
    NEED_IP_FORWARD="1"
fi

if [[ -n "$EXIT_NODE" ]]; then
    TS_UP_ARGS="$TS_UP_ARGS --advertise-exit-node"
    NEED_IP_FORWARD="1"
fi

echo "Creating Tailscale installation script..."
sudo tee /mnt/rpi-root/root/setup-tailscale.sh > /dev/null << SETUP_SCRIPT
#!/bin/bash
set -e

echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

SETUP_SCRIPT

if [[ -n "$NEED_IP_FORWARD" ]]; then
    sudo tee -a /mnt/rpi-root/root/setup-tailscale.sh > /dev/null << 'SETUP_SCRIPT'
echo "Enabling IP forwarding..."
echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf

SETUP_SCRIPT
fi

sudo tee -a /mnt/rpi-root/root/setup-tailscale.sh > /dev/null << SETUP_SCRIPT
echo "Starting Tailscale..."
tailscale up $TS_UP_ARGS

echo "Tailscale setup complete!"
rm /root/setup-tailscale.sh
SETUP_SCRIPT
sudo chmod +x /mnt/rpi-root/root/setup-tailscale.sh

echo "Creating first-boot service..."
sudo tee /mnt/rpi-root/etc/systemd/system/tailscale-first-boot.service > /dev/null << 'SERVICE'
[Unit]
Description=Setup Tailscale on first boot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/root/setup-tailscale.sh
RemainAfterExit=yes
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
SERVICE

sudo ln -sf /etc/systemd/system/tailscale-first-boot.service \
    /mnt/rpi-root/etc/systemd/system/multi-user.target.wants/tailscale-first-boot.service

echo "Enabling SSH..."
sudo touch /mnt/rpi-boot/ssh

echo "Copying image to output directory..."
mkdir -p "$OUTPUT_DIR"
OUTPUT_IMAGE="$OUTPUT_DIR/raspios-tailscale-${HOSTNAME}.img"
cp raspios.img "$OUTPUT_IMAGE"

echo "Creating configuration summary..."
cat > "$OUTPUT_DIR/tailscale-config-${HOSTNAME}.txt" << EOF
Raspberry Pi Tailscale Configuration
=====================================

Hostname: $HOSTNAME
Subnet Routes: ${SUBNET_ROUTES:-none}
Exit Node: ${EXIT_NODE:-no}

After first boot, the Pi will:
1. Install Tailscale
2. Authenticate using the provided auth key
3. Appear in your Tailscale admin console

If advertising subnet routes, approve them in the admin console:
https://login.tailscale.com/admin/machines

EOF

cat "$OUTPUT_DIR/tailscale-config-${HOSTNAME}.txt"

echo
echo "===================================="
echo "Image customization complete!"
echo "===================================="
echo "Output image: $OUTPUT_IMAGE"
echo "Config saved: $OUTPUT_DIR/tailscale-config-${HOSTNAME}.txt"
echo
echo "To flash to SD card:"
echo "  sudo dd if=$OUTPUT_IMAGE of=/dev/sdX bs=4M status=progress conv=fsync"
echo
