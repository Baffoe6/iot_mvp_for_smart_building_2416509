"""
AWS Lambda Function - Alert Handler
Processes IoT sensor alerts and sends notifications via SNS

Triggered by:
- High CO2 levels (>1200 ppm)
- High temperature (>27°C)
- Low battery (<2400 mV)

Author: IoT MVP Team
Version: 1.0.0
"""

import json
import os
import boto3
from datetime import datetime
from typing import Dict, Any

# Initialize AWS clients
sns = boto3.client('sns')

# Configuration
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'prod')

# Alert thresholds
THRESHOLDS = {
    'co2_critical': 1500,  # ppm
    'co2_warning': 1200,   # ppm
    'temp_critical': 30.0,  # °C
    'temp_warning': 27.0,   # °C
    'battery_critical': 2200,  # mV
    'battery_warning': 2400    # mV
}

# Alert cooldown (seconds) - prevent notification spam
ALERT_COOLDOWN = 300  # 5 minutes

# In-memory cache for alert deduplication (Lambda warm starts)
recent_alerts = {}

def lambda_handler(event, context):
    """
    Main Lambda handler function
    
    Args:
        event: IoT message event
        context: Lambda context
    
    Returns:
        dict: Response with statusCode and message
    """
    try:
        print(f"Received event: {json.dumps(event)}")
        
        # Parse sensor data
        sensor_data = event.get('sensor_data', {})
        metadata = event.get('metadata', {})
        
        device_id = event.get('device_id', 'unknown')
        building_id = event.get('building_id', 'unknown')
        gateway_id = event.get('gateway_id', 'unknown')
        timestamp = event.get('timestamp', int(datetime.now().timestamp()))
        
        # Determine alert type and severity
        alerts = []
        
        # Check CO2 levels
        co2_ppm = sensor_data.get('co2_ppm')
        if co2_ppm:
            if co2_ppm >= THRESHOLDS['co2_critical']:
                alerts.append({
                    'type': 'co2',
                    'severity': 'CRITICAL',
                    'value': co2_ppm,
                    'threshold': THRESHOLDS['co2_critical'],
                    'message': f"CRITICAL: CO2 level at {co2_ppm} ppm (threshold: {THRESHOLDS['co2_critical']} ppm)"
                })
            elif co2_ppm >= THRESHOLDS['co2_warning']:
                alerts.append({
                    'type': 'co2',
                    'severity': 'WARNING',
                    'value': co2_ppm,
                    'threshold': THRESHOLDS['co2_warning'],
                    'message': f"WARNING: CO2 level at {co2_ppm} ppm (threshold: {THRESHOLDS['co2_warning']} ppm)"
                })
        
        # Check temperature
        temp_c = sensor_data.get('temperature_c')
        if temp_c:
            if temp_c >= THRESHOLDS['temp_critical']:
                alerts.append({
                    'type': 'temperature',
                    'severity': 'CRITICAL',
                    'value': temp_c,
                    'threshold': THRESHOLDS['temp_critical'],
                    'message': f"CRITICAL: Temperature at {temp_c}°C (threshold: {THRESHOLDS['temp_critical']}°C)"
                })
            elif temp_c >= THRESHOLDS['temp_warning']:
                alerts.append({
                    'type': 'temperature',
                    'severity': 'WARNING',
                    'value': temp_c,
                    'threshold': THRESHOLDS['temp_warning'],
                    'message': f"WARNING: Temperature at {temp_c}°C (threshold: {THRESHOLDS['temp_warning']}°C)"
                })
        
        # Check battery voltage
        battery_mv = sensor_data.get('battery_mv')
        if battery_mv:
            if battery_mv <= THRESHOLDS['battery_critical']:
                alerts.append({
                    'type': 'battery',
                    'severity': 'CRITICAL',
                    'value': battery_mv,
                    'threshold': THRESHOLDS['battery_critical'],
                    'message': f"CRITICAL: Battery voltage at {battery_mv} mV (threshold: {THRESHOLDS['battery_critical']} mV)"
                })
            elif battery_mv <= THRESHOLDS['battery_warning']:
                alerts.append({
                    'type': 'battery',
                    'severity': 'WARNING',
                    'value': battery_mv,
                    'threshold': THRESHOLDS['battery_warning'],
                    'message': f"WARNING: Battery voltage at {battery_mv} mV (threshold: {THRESHOLDS['battery_warning']} mV)"
                })
        
        # Process and send alerts
        notifications_sent = 0
        
        for alert in alerts:
            # Check for alert cooldown (deduplication)
            alert_key = f"{device_id}:{alert['type']}"
            current_time = datetime.now().timestamp()
            
            if alert_key in recent_alerts:
                last_alert_time = recent_alerts[alert_key]
                if (current_time - last_alert_time) < ALERT_COOLDOWN:
                    print(f"Alert {alert_key} suppressed (cooldown active)")
                    continue
            
            # Send notification
            if send_notification(
                alert=alert,
                device_id=device_id,
                building_id=building_id,
                gateway_id=gateway_id,
                timestamp=timestamp,
                sensor_data=sensor_data
            ):
                notifications_sent += 1
                recent_alerts[alert_key] = current_time
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Alerts processed successfully',
                'alerts_detected': len(alerts),
                'notifications_sent': notifications_sent
            })
        }
    
    except Exception as e:
        print(f"Error processing alert: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error processing alert',
                'error': str(e)
            })
        }

def send_notification(alert: Dict, device_id: str, building_id: str, 
                     gateway_id: str, timestamp: int, sensor_data: Dict) -> bool:
    """
    Send alert notification via SNS
    
    Args:
        alert: Alert details
        device_id: Device identifier
        building_id: Building identifier
        gateway_id: Gateway identifier
        timestamp: Unix timestamp
        sensor_data: Full sensor data payload
    
    Returns:
        bool: True if notification sent successfully
    """
    try:
        # Format timestamp
        dt = datetime.fromtimestamp(timestamp)
        time_str = dt.strftime('%Y-%m-%d %H:%M:%S')
        
        # Construct notification message
        subject = f"[{alert['severity']}] IoT Sensor Alert - {alert['type'].upper()}"
        
        message = f"""
IoT MVP - Sensor Alert Notification

ALERT DETAILS:
--------------
Severity: {alert['severity']}
Type: {alert['type'].upper()}
Message: {alert['message']}

DEVICE INFORMATION:
------------------
Device ID: {device_id}
Building ID: {building_id}
Gateway ID: {gateway_id}
Timestamp: {time_str}

SENSOR READINGS:
---------------
CO2: {sensor_data.get('co2_ppm', 'N/A')} ppm
Temperature: {sensor_data.get('temperature_c', 'N/A')}°C
Humidity: {sensor_data.get('humidity_rh', 'N/A')}%
Occupancy: {'Yes' if sensor_data.get('occupancy') else 'No'}
Battery: {sensor_data.get('battery_mv', 'N/A')} mV

ACTION REQUIRED:
---------------
{get_action_recommendation(alert)}

--
IoT MVP Alert System ({ENVIRONMENT})
"""
        
        # Send SNS notification
        response = sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        
        print(f"SNS notification sent: MessageId={response['MessageId']}")
        return True
    
    except Exception as e:
        print(f"Failed to send SNS notification: {str(e)}")
        return False

def get_action_recommendation(alert: Dict) -> str:
    """
    Get recommended action based on alert type and severity
    
    Args:
        alert: Alert details
    
    Returns:
        str: Recommended action
    """
    recommendations = {
        ('co2', 'CRITICAL'): "IMMEDIATE: Increase ventilation, evacuate room if necessary. Check HVAC system operation.",
        ('co2', 'WARNING'): "Increase ventilation rate, reduce occupancy if possible. Monitor trend closely.",
        ('temperature', 'CRITICAL'): "IMMEDIATE: Check HVAC system, reduce heat sources, consider relocating occupants.",
        ('temperature', 'WARNING'): "Adjust thermostat setpoint, check for heat sources (equipment, direct sunlight).",
        ('battery', 'CRITICAL'): "URGENT: Schedule battery replacement within 24 hours to avoid service interruption.",
        ('battery', 'WARNING'): "Schedule battery replacement within next maintenance window (1-2 weeks)."
    }
    
    key = (alert['type'], alert['severity'])
    return recommendations.get(key, "Monitor situation and take appropriate action per facility protocols.")

# For local testing
if __name__ == "__main__":
    # Sample event for testing
    test_event = {
        "device_id": "a4c138f5a1b2",
        "building_id": "building-001",
        "gateway_id": "gateway-abcd1234",
        "timestamp": int(datetime.now().timestamp()),
        "sensor_data": {
            "co2_ppm": 1350,
            "temperature_c": 28.5,
            "humidity_rh": 55.0,
            "occupancy": True,
            "battery_mv": 2300
        },
        "metadata": {
            "rssi": -65
        }
    }
    
    # Mock environment variables
    os.environ['SNS_TOPIC_ARN'] = 'arn:aws:sns:eu-west-1:123456789012:iot-mvp-alerts'
    os.environ['ENVIRONMENT'] = 'dev'
    
    # Run handler
    result = lambda_handler(test_event, None)
    print(json.dumps(result, indent=2))
