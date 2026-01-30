#!/usr/bin/env python3
"""
IoT MVP Gateway - BLE to MQTT Bridge
Raspberry Pi 4 gateway application for scanning BLE advertisements
and forwarding sensor data to AWS IoT Core via MQTT/TLS

Author: IoT MVP Team
Date: January 2026
Version: 1.0.0
"""

import asyncio
import json
import sqlite3
import signal
import sys
import time
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
import struct
import hashlib

from bleak import BleakScanner, BleakClient
import paho.mqtt.client as mqtt
import boto3
from cryptography import x509
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding

# Configuration
CONFIG = {
    "gateway_id": None,  # Auto-detected from MAC address
    "building_id": "building-001",
    "ble_scan_interval": 5,  # seconds
    "mqtt_broker": "a3xxxxxxx-ats.iot.eu-west-1.amazonaws.com",
    "mqtt_port": 8883,
    "mqtt_keepalive": 60,
    "mqtt_qos": 1,  # At-least-once delivery
    "ca_cert_path": "/etc/iot-mvp/AmazonRootCA1.pem",
    "client_cert_path": "/etc/iot-mvp/gateway.crt",
    "client_key_path": "/etc/iot-mvp/gateway.key",
    "buffer_db_path": "/var/lib/iot-mvp/buffer.db",
    "buffer_retention_days": 7,
    "log_level": "INFO",
    "max_devices": 20,
}

# BLE Advertisement Format (matches firmware)
# Byte 0-1: Manufacturer ID (0xFFFF = test)
# Byte 2-3: CO2 (uint16_t, ppm)
# Byte 4-7: Temperature (float, Celsius)
# Byte 8-11: Humidity (float, %)
# Byte 12: Occupancy (uint8_t, 0/1)
# Byte 13-16: Timestamp (uint32_t, Unix)
# Byte 17-18: Battery (uint16_t, mV)
# Byte 19-20: CRC16

class GatewayApp:
    """Main gateway application"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.logger = self._setup_logging()
        self.gateway_id = self._get_gateway_id()
        self.mqtt_client = None
        self.mqtt_connected = False
        self.db_conn = None
        self.known_devices = {}  # device_id -> last_seen_timestamp
        self.running = True
        
    def _setup_logging(self) -> logging.Logger:
        """Configure logging"""
        logging.basicConfig(
            level=getattr(logging, self.config["log_level"]),
            format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
            handlers=[
                logging.FileHandler('/var/log/iot-mvp-gateway.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        return logging.getLogger('IoTMVP-Gateway')
    
    def _get_gateway_id(self) -> str:
        """Get unique gateway ID from MAC address"""
        try:
            with open('/sys/class/net/eth0/address', 'r') as f:
                mac = f.read().strip().replace(':', '')
                gateway_id = f"gateway-{mac[-8:]}"
                self.logger.info(f"Gateway ID: {gateway_id}")
                return gateway_id
        except Exception as e:
            self.logger.error(f"Failed to get MAC address: {e}")
            return "gateway-unknown"
    
    def _init_database(self):
        """Initialize SQLite buffer database"""
        try:
            Path(self.config["buffer_db_path"]).parent.mkdir(parents=True, exist_ok=True)
            self.db_conn = sqlite3.connect(self.config["buffer_db_path"], check_same_thread=False)
            cursor = self.db_conn.cursor()
            
            # Create telemetry buffer table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS telemetry_buffer (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    device_id TEXT NOT NULL,
                    timestamp INTEGER NOT NULL,
                    co2_ppm INTEGER,
                    temperature_c REAL,
                    humidity_rh REAL,
                    occupancy INTEGER,
                    battery_mv INTEGER,
                    rssi INTEGER,
                    received_at INTEGER NOT NULL,
                    published INTEGER DEFAULT 0,
                    published_at INTEGER
                )
            ''')
            
            # Create index for efficient queries
            cursor.execute('''
                CREATE INDEX IF NOT EXISTS idx_published 
                ON telemetry_buffer(published, received_at)
            ''')
            
            cursor.execute('''
                CREATE INDEX IF NOT EXISTS idx_device_timestamp 
                ON telemetry_buffer(device_id, timestamp DESC)
            ''')
            
            self.db_conn.commit()
            self.logger.info("Database initialized successfully")
            
        except Exception as e:
            self.logger.error(f"Database initialization failed: {e}")
            raise
    
    def _init_mqtt(self):
        """Initialize MQTT client with TLS"""
        try:
            self.mqtt_client = mqtt.Client(
                client_id=self.gateway_id,
                protocol=mqtt.MQTTv5
            )
            
            # Set TLS certificates
            self.mqtt_client.tls_set(
                ca_certs=self.config["ca_cert_path"],
                certfile=self.config["client_cert_path"],
                keyfile=self.config["client_key_path"]
            )
            
            # Set callbacks
            self.mqtt_client.on_connect = self._on_mqtt_connect
            self.mqtt_client.on_disconnect = self._on_mqtt_disconnect
            self.mqtt_client.on_publish = self._on_mqtt_publish
            
            # Connect to AWS IoT Core
            self.logger.info(f"Connecting to MQTT broker: {self.config['mqtt_broker']}")
            self.mqtt_client.connect(
                self.config["mqtt_broker"],
                self.config["mqtt_port"],
                self.config["mqtt_keepalive"]
            )
            
            # Start network loop in background
            self.mqtt_client.loop_start()
            
        except Exception as e:
            self.logger.error(f"MQTT initialization failed: {e}")
            raise
    
    def _on_mqtt_connect(self, client, userdata, flags, rc, properties=None):
        """MQTT connection callback"""
        if rc == 0:
            self.mqtt_connected = True
            self.logger.info("Connected to MQTT broker successfully")
            
            # Subscribe to OTA update topic
            ota_topic = f"building/{self.config['building_id']}/gateway/{self.gateway_id}/ota/request"
            client.subscribe(ota_topic, qos=1)
            self.logger.info(f"Subscribed to OTA topic: {ota_topic}")
            
            # Publish gateway online status
            status_topic = f"building/{self.config['building_id']}/gateway/{self.gateway_id}/status"
            status_payload = {
                "status": "online",
                "timestamp": int(time.time()),
                "version": "1.0.0",
                "uptime_seconds": 0
            }
            client.publish(status_topic, json.dumps(status_payload), qos=1, retain=True)
            
            # Start publishing buffered messages
            asyncio.create_task(self._publish_buffered_messages())
            
        else:
            self.logger.error(f"MQTT connection failed with code: {rc}")
            self.mqtt_connected = False
    
    def _on_mqtt_disconnect(self, client, userdata, rc):
        """MQTT disconnection callback"""
        self.mqtt_connected = False
        self.logger.warning(f"Disconnected from MQTT broker (code {rc})")
    
    def _on_mqtt_publish(self, client, userdata, mid):
        """MQTT publish callback"""
        self.logger.debug(f"Message {mid} published successfully")
    
    def _parse_ble_advertisement(self, device, advertisement_data) -> Optional[Dict]:
        """Parse BLE advertisement data from sensor device"""
        try:
            manufacturer_data = advertisement_data.manufacturer_data
            
            if not manufacturer_data:
                return None
            
            # Look for our manufacturer ID (0xFFFF)
            if 0xFFFF not in manufacturer_data:
                return None
            
            data = manufacturer_data[0xFFFF]
            
            # Verify minimum length
            if len(data) < 21:
                self.logger.warning(f"Advertisement data too short: {len(data)} bytes")
                return None
            
            # Parse payload
            co2_ppm = struct.unpack('<H', data[0:2])[0]
            temperature_c = struct.unpack('<f', data[2:6])[0]
            humidity_rh = struct.unpack('<f', data[6:10])[0]
            occupancy = data[10]
            timestamp = struct.unpack('<I', data[11:15])[0]
            battery_mv = struct.unpack('<H', data[15:17])[0]
            crc_received = struct.unpack('<H', data[17:19])[0]
            
            # Verify CRC16
            crc_calculated = self._calculate_crc16(data[0:17])
            if crc_calculated != crc_received:
                self.logger.warning(f"CRC mismatch: calculated={crc_calculated:04x}, received={crc_received:04x}")
                return None
            
            # Extract device ID from BLE address
            device_id = device.address.replace(':', '').lower()
            
            # Get RSSI
            rssi = advertisement_data.rssi if hasattr(advertisement_data, 'rssi') else None
            
            return {
                "device_id": device_id,
                "co2_ppm": co2_ppm,
                "temperature_c": round(temperature_c, 1),
                "humidity_rh": round(humidity_rh, 1),
                "occupancy": bool(occupancy),
                "timestamp": timestamp,
                "battery_mv": battery_mv,
                "rssi": rssi,
                "received_at": int(time.time())
            }
            
        except Exception as e:
            self.logger.error(f"Failed to parse BLE advertisement: {e}")
            return None
    
    def _calculate_crc16(self, data: bytes) -> int:
        """Calculate CRC16-CCITT"""
        crc = 0xFFFF
        for byte in data:
            crc ^= byte << 8
            for _ in range(8):
                if crc & 0x8000:
                    crc = (crc << 1) ^ 0x1021
                else:
                    crc = crc << 1
                crc &= 0xFFFF
        return crc
    
    def _buffer_telemetry(self, telemetry: Dict):
        """Store telemetry in local buffer"""
        try:
            cursor = self.db_conn.cursor()
            cursor.execute('''
                INSERT INTO telemetry_buffer 
                (device_id, timestamp, co2_ppm, temperature_c, humidity_rh, 
                 occupancy, battery_mv, rssi, received_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                telemetry["device_id"],
                telemetry["timestamp"],
                telemetry["co2_ppm"],
                telemetry["temperature_c"],
                telemetry["humidity_rh"],
                int(telemetry["occupancy"]),
                telemetry["battery_mv"],
                telemetry["rssi"],
                telemetry["received_at"]
            ))
            self.db_conn.commit()
            self.logger.debug(f"Telemetry buffered for device {telemetry['device_id']}")
            
        except Exception as e:
            self.logger.error(f"Failed to buffer telemetry: {e}")
    
    async def _publish_telemetry(self, telemetry: Dict):
        """Publish telemetry to MQTT"""
        try:
            if not self.mqtt_connected:
                self.logger.warning("MQTT not connected, buffering only")
                return
            
            # Construct MQTT topic
            topic = (f"building/{self.config['building_id']}/"
                    f"gateway/{self.gateway_id}/"
                    f"device/{telemetry['device_id']}/telemetry")
            
            # Construct payload
            payload = {
                "version": "1.0",
                "gateway_id": self.gateway_id,
                "device_id": telemetry["device_id"],
                "timestamp": telemetry["timestamp"],
                "received_at": telemetry["received_at"],
                "sensor_data": {
                    "co2_ppm": telemetry["co2_ppm"],
                    "temperature_c": telemetry["temperature_c"],
                    "humidity_rh": telemetry["humidity_rh"],
                    "occupancy": telemetry["occupancy"],
                    "battery_mv": telemetry["battery_mv"]
                },
                "metadata": {
                    "rssi": telemetry["rssi"],
                    "latency_ms": (telemetry["received_at"] - telemetry["timestamp"]) * 1000
                }
            }
            
            # Publish to MQTT
            result = self.mqtt_client.publish(
                topic,
                json.dumps(payload),
                qos=self.config["mqtt_qos"],
                retain=False
            )
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                self.logger.info(f"Published telemetry for {telemetry['device_id']}: "
                               f"CO2={telemetry['co2_ppm']} ppm, Temp={telemetry['temperature_c']}°C")
                
                # Mark as published in database
                cursor = self.db_conn.cursor()
                cursor.execute('''
                    UPDATE telemetry_buffer 
                    SET published = 1, published_at = ?
                    WHERE device_id = ? AND timestamp = ?
                ''', (int(time.time()), telemetry["device_id"], telemetry["timestamp"]))
                self.db_conn.commit()
            else:
                self.logger.error(f"MQTT publish failed: {result.rc}")
                
        except Exception as e:
            self.logger.error(f"Failed to publish telemetry: {e}")
    
    async def _publish_buffered_messages(self):
        """Publish buffered messages when connection restored"""
        while self.running:
            try:
                if not self.mqtt_connected:
                    await asyncio.sleep(10)
                    continue
                
                # Get unpublished messages
                cursor = self.db_conn.cursor()
                cursor.execute('''
                    SELECT device_id, timestamp, co2_ppm, temperature_c, humidity_rh,
                           occupancy, battery_mv, rssi, received_at
                    FROM telemetry_buffer
                    WHERE published = 0
                    ORDER BY received_at ASC
                    LIMIT 100
                ''')
                
                rows = cursor.fetchall()
                
                if rows:
                    self.logger.info(f"Publishing {len(rows)} buffered messages")
                    
                    for row in rows:
                        telemetry = {
                            "device_id": row[0],
                            "timestamp": row[1],
                            "co2_ppm": row[2],
                            "temperature_c": row[3],
                            "humidity_rh": row[4],
                            "occupancy": bool(row[5]),
                            "battery_mv": row[6],
                            "rssi": row[7],
                            "received_at": row[8]
                        }
                        
                        await self._publish_telemetry(telemetry)
                        await asyncio.sleep(0.1)  # Rate limiting
                
                # Cleanup old buffered data
                retention_timestamp = int(time.time()) - (self.config["buffer_retention_days"] * 86400)
                cursor.execute('''
                    DELETE FROM telemetry_buffer
                    WHERE received_at < ? AND published = 1
                ''', (retention_timestamp,))
                deleted = cursor.rowcount
                if deleted > 0:
                    self.logger.info(f"Deleted {deleted} old buffered messages")
                    self.db_conn.commit()
                
                await asyncio.sleep(60)  # Check every minute
                
            except Exception as e:
                self.logger.error(f"Error in buffered message publisher: {e}")
                await asyncio.sleep(60)
    
    async def _scan_ble_devices(self):
        """Continuously scan for BLE advertisements"""
        self.logger.info("Starting BLE scanning...")
        
        while self.running:
            try:
                # Scan for BLE devices
                devices = await BleakScanner.discover(
                    timeout=self.config["ble_scan_interval"],
                    return_adv=True
                )
                
                for device, advertisement_data in devices.values():
                    # Parse advertisement
                    telemetry = self._parse_ble_advertisement(device, advertisement_data)
                    
                    if telemetry:
                        # Update known devices
                        self.known_devices[telemetry["device_id"]] = telemetry["received_at"]
                        
                        # Buffer locally
                        self._buffer_telemetry(telemetry)
                        
                        # Publish to MQTT
                        await self._publish_telemetry(telemetry)
                
                # Log discovered devices
                self.logger.info(f"Active devices: {len(self.known_devices)}")
                
            except Exception as e:
                self.logger.error(f"BLE scanning error: {e}")
                await asyncio.sleep(5)
    
    async def _health_check_loop(self):
        """Periodic health check and status reporting"""
        start_time = time.time()
        
        while self.running:
            try:
                uptime = int(time.time() - start_time)
                
                # Publish health status
                status_topic = f"building/{self.config['building_id']}/gateway/{self.gateway_id}/status"
                status_payload = {
                    "status": "online",
                    "timestamp": int(time.time()),
                    "version": "1.0.0",
                    "uptime_seconds": uptime,
                    "mqtt_connected": self.mqtt_connected,
                    "active_devices": len(self.known_devices),
                    "buffered_messages": self._get_buffered_count()
                }
                
                if self.mqtt_connected:
                    self.mqtt_client.publish(
                        status_topic,
                        json.dumps(status_payload),
                        qos=1,
                        retain=True
                    )
                
                self.logger.debug(f"Health check: uptime={uptime}s, devices={len(self.known_devices)}")
                
                await asyncio.sleep(300)  # Every 5 minutes
                
            except Exception as e:
                self.logger.error(f"Health check error: {e}")
                await asyncio.sleep(60)
    
    def _get_buffered_count(self) -> int:
        """Get count of unpublished buffered messages"""
        try:
            cursor = self.db_conn.cursor()
            cursor.execute('SELECT COUNT(*) FROM telemetry_buffer WHERE published = 0')
            return cursor.fetchone()[0]
        except:
            return -1
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.running = False
    
    async def run(self):
        """Main application loop"""
        try:
            # Initialize components
            self._init_database()
            self._init_mqtt()
            
            # Register signal handlers
            signal.signal(signal.SIGINT, self._signal_handler)
            signal.signal(signal.SIGTERM, self._signal_handler)
            
            self.logger.info("Gateway application started successfully")
            
            # Run concurrent tasks
            await asyncio.gather(
                self._scan_ble_devices(),
                self._publish_buffered_messages(),
                self._health_check_loop()
            )
            
        except Exception as e:
            self.logger.error(f"Fatal error in main loop: {e}")
            raise
        
        finally:
            # Cleanup
            self.logger.info("Shutting down...")
            
            if self.mqtt_client:
                # Publish offline status
                status_topic = f"building/{self.config['building_id']}/gateway/{self.gateway_id}/status"
                status_payload = {"status": "offline", "timestamp": int(time.time())}
                self.mqtt_client.publish(status_topic, json.dumps(status_payload), qos=1, retain=True)
                self.mqtt_client.loop_stop()
                self.mqtt_client.disconnect()
            
            if self.db_conn:
                self.db_conn.close()
            
            self.logger.info("Gateway application stopped")

def main():
    """Application entry point"""
    print("IoT MVP Gateway v1.0.0")
    print("=" * 50)
    
    # Create and run gateway application
    gateway = GatewayApp(CONFIG)
    asyncio.run(gateway.run())

if __name__ == "__main__":
    main()
