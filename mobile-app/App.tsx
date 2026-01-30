import { StatusBar } from 'expo-status-bar';
import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  RefreshControl,
  SafeAreaView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

// Mock device data
const mockDevices = [
  {
    id: 'device-001',
    name: 'Conference Room A',
    co2: 680,
    temperature: 22.5,
    humidity: 45.2,
    occupancy: true,
    battery: 3250,
  },
  {
    id: 'device-002',
    name: 'Office Wing B',
    co2: 520,
    temperature: 21.8,
    humidity: 42.1,
    occupancy: false,
    battery: 3100,
  },
  {
    id: 'device-003',
    name: 'Meeting Room C',
    co2: 1150,
    temperature: 24.2,
    humidity: 48.5,
    occupancy: true,
    battery: 2980,
  },
];

export default function App() {
  const [refreshing, setRefreshing] = useState(false);

  const onRefresh = () => {
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 1000);
  };

  const getCO2Status = (co2: number) => {
    if (co2 < 800) return { label: 'Good', color: '#4caf50' };
    if (co2 < 1000) return { label: 'Moderate', color: '#ff9800' };
    return { label: 'Poor', color: '#f44336' };
  };

  const getBatteryColor = (voltage: number) => {
    if (voltage > 3000) return '#4caf50';
    if (voltage > 2600) return '#ff9800';
    return '#f44336';
  };

  const avgCO2 = Math.round(
    mockDevices.reduce((acc, d) => acc + d.co2, 0) / mockDevices.length
  );
  const avgTemp = (
    mockDevices.reduce((acc, d) => acc + d.temperature, 0) / mockDevices.length
  ).toFixed(1);
  const avgHumidity = (
    mockDevices.reduce((acc, d) => acc + d.humidity, 0) / mockDevices.length
  ).toFixed(1);
  const occupiedCount = mockDevices.filter(d => d.occupancy).length;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="light" />
      
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerContent}>
          <Ionicons name="cloud-outline" size={28} color="#fff" />
          <Text style={styles.headerTitle}>IoT MVP Mobile</Text>
        </View>
        <View style={styles.liveIndicator}>
          <View style={styles.liveDot} />
          <Text style={styles.liveText}>Live</Text>
        </View>
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* Overview Cards */}
        <View style={styles.overviewContainer}>
          <View style={styles.overviewRow}>
            <View style={[styles.overviewCard, { backgroundColor: '#e3f2fd' }]}>
              <Ionicons name="cloud-outline" size={32} color="#1976d2" />
              <Text style={styles.overviewValue}>{avgCO2}</Text>
              <Text style={styles.overviewLabel}>ppm CO₂</Text>
              <View style={[styles.badge, { backgroundColor: getCO2Status(avgCO2).color }]}>
                <Text style={styles.badgeText}>{getCO2Status(avgCO2).label}</Text>
              </View>
            </View>

            <View style={[styles.overviewCard, { backgroundColor: '#ffebee' }]}>
              <Ionicons name="thermometer-outline" size={32} color="#f44336" />
              <Text style={styles.overviewValue}>{avgTemp}°C</Text>
              <Text style={styles.overviewLabel}>Temperature</Text>
              <Text style={styles.overviewSubtext}>Comfortable</Text>
            </View>
          </View>

          <View style={styles.overviewRow}>
            <View style={[styles.overviewCard, { backgroundColor: '#e1f5fe' }]}>
              <Ionicons name="water-outline" size={32} color="#03a9f4" />
              <Text style={styles.overviewValue}>{avgHumidity}%</Text>
              <Text style={styles.overviewLabel}>Humidity</Text>
              <Text style={styles.overviewSubtext}>Optimal</Text>
            </View>

            <View style={[styles.overviewCard, { backgroundColor: '#fce4ec' }]}>
              <Ionicons name="people-outline" size={32} color="#e91e63" />
              <Text style={styles.overviewValue}>{occupiedCount}/{mockDevices.length}</Text>
              <Text style={styles.overviewLabel}>Occupied</Text>
              <Text style={styles.overviewSubtext}>Active spaces</Text>
            </View>
          </View>
        </View>

        {/* Devices Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>All Devices</Text>
          {mockDevices.map((device) => (
            <View key={device.id} style={styles.deviceCard}>
              <View style={styles.deviceHeader}>
                <Text style={styles.deviceName}>{device.name}</Text>
                {device.occupancy ? (
                  <View style={[styles.statusBadge, { backgroundColor: '#1976d2' }]}>
                    <Text style={styles.statusBadgeText}>Occupied</Text>
                  </View>
                ) : (
                  <View style={[styles.statusBadge, { backgroundColor: '#9e9e9e' }]}>
                    <Text style={styles.statusBadgeText}>Vacant</Text>
                  </View>
                )}
              </View>

              <View style={styles.deviceMetrics}>
                <View style={styles.metricRow}>
                  <Text style={styles.metricLabel}>CO₂</Text>
                  <View style={styles.metricValueContainer}>
                    <Text style={styles.metricValue}>{device.co2} ppm</Text>
                    <View style={[styles.metricBadge, { backgroundColor: getCO2Status(device.co2).color }]}>
                      <Text style={styles.metricBadgeText}>{getCO2Status(device.co2).label}</Text>
                    </View>
                  </View>
                </View>

                <View style={styles.metricRow}>
                  <Text style={styles.metricLabel}>Temperature</Text>
                  <Text style={styles.metricValue}>{device.temperature}°C</Text>
                </View>

                <View style={styles.metricRow}>
                  <Text style={styles.metricLabel}>Humidity</Text>
                  <Text style={styles.metricValue}>{device.humidity}%</Text>
                </View>

                <View style={styles.metricRow}>
                  <View style={styles.batteryLabel}>
                    <Ionicons name="battery-full-outline" size={16} color="#666" />
                    <Text style={styles.metricLabel}> Battery</Text>
                  </View>
                  <View style={styles.metricValueContainer}>
                    <Text style={styles.metricValue}>{device.battery} mV</Text>
                    <View style={[styles.metricBadge, { backgroundColor: getBatteryColor(device.battery) }]}>
                      <Text style={styles.metricBadgeText}>
                        {device.battery > 3000 ? 'Good' : device.battery > 2600 ? 'Low' : 'Critical'}
                      </Text>
                    </View>
                  </View>
                </View>
              </View>

              <Text style={styles.deviceTimestamp}>
                Last update: {new Date().toLocaleTimeString()}
              </Text>
            </View>
          ))}
        </View>

        {/* Footer */}
        <View style={styles.footer}>
          <Text style={styles.footerText}>IoT MVP v1.0.0</Text>
          <Text style={styles.footerSubtext}>
            Monitoring {mockDevices.length} devices • 18.2% energy savings
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#1976d2',
    paddingHorizontal: 20,
    paddingVertical: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#fff',
    marginLeft: 10,
  },
  liveIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#4caf50',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  liveDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#fff',
    marginRight: 6,
  },
  liveText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  content: {
    flex: 1,
  },
  overviewContainer: {
    padding: 16,
  },
  overviewRow: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  overviewCard: {
    flex: 1,
    padding: 16,
    borderRadius: 12,
    marginHorizontal: 6,
    alignItems: 'center',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 1.41,
  },
  overviewValue: {
    fontSize: 28,
    fontWeight: 'bold',
    marginTop: 8,
    color: '#212121',
  },
  overviewLabel: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  overviewSubtext: {
    fontSize: 11,
    color: '#999',
    marginTop: 2,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
    marginTop: 8,
  },
  badgeText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '600',
  },
  section: {
    padding: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#212121',
    marginBottom: 12,
  },
  deviceCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 1.41,
  },
  deviceHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  deviceName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#212121',
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  statusBadgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  deviceMetrics: {
    marginBottom: 8,
  },
  metricRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  metricLabel: {
    fontSize: 14,
    color: '#666',
  },
  metricValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#212121',
  },
  metricValueContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  metricBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 8,
  },
  metricBadgeText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '600',
  },
  batteryLabel: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  deviceTimestamp: {
    fontSize: 11,
    color: '#999',
    marginTop: 8,
  },
  footer: {
    padding: 20,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  footerSubtext: {
    fontSize: 10,
    color: '#999',
  },
});
