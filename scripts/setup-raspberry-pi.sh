#!/bin/bash
# IoT MVP - Raspberry Pi Gateway Setup Script
# This script sets up a Raspberry Pi as a BLE-to-MQTT gateway

set -e

echo "========================================"
echo "IoT MVP - Raspberry Pi Gateway Setup"
echo "========================================"
echo ""

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠ Warning: This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Python and dependencies
echo ""
echo "Installing Python and dependencies..."
sudo apt-get install -y python3 python3-pip python3-venv
sudo apt-get install -y bluetooth libbluetooth-dev bluez

# Install required system packages for BLE
echo ""
echo "Installing Bluetooth packages..."
sudo apt-get install -y libglib2.0-dev

# Create project directory
PROJECT_DIR="/opt/iot-mvp-gateway"
echo ""
echo "Creating project directory: $PROJECT_DIR"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# Copy gateway files (assumes script is run from project root)
echo ""
echo "Copying gateway files..."
cp -r gateway/* $PROJECT_DIR/

# Create virtual environment
echo ""
echo "Creating Python virtual environment..."
cd $PROJECT_DIR
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo ""
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create systemd service
echo ""
echo "Creating systemd service..."
sudo tee /etc/systemd/system/iot-gateway.service > /dev/null <<EOF
[Unit]
Description=IoT MVP BLE Gateway
After=network.target bluetooth.service
Requires=bluetooth.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/venv/bin/python $PROJECT_DIR/gateway.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create configuration directory
echo ""
echo "Creating configuration directory..."
sudo mkdir -p /etc/iot-mvp
sudo chown $USER:$USER /etc/iot-mvp

echo ""
echo "========================================"
echo "✓ Setup complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Configure AWS IoT Core credentials in $PROJECT_DIR/config.json"
echo "2. Place certificates in /etc/iot-mvp/"
echo "3. Enable and start the service:"
echo "   sudo systemctl enable iot-gateway"
echo "   sudo systemctl start iot-gateway"
echo "4. Check status:"
echo "   sudo systemctl status iot-gateway"
echo "   sudo journalctl -u iot-gateway -f"
echo ""
