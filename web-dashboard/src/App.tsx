import { useState } from 'react'
import {
  AppBar,
  Box,
  Container,
  Grid,
  Paper,
  Toolbar,
  Typography,
  Card,
  CardContent,
  Chip,
} from '@mui/material'
import {
  AirOutlined,
  ThermostatOutlined,
  WaterDropOutlined,
  PeopleOutline,
  BatteryFullOutlined,
} from '@mui/icons-material'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts'

// Mock data for demonstration
const mockDevices = [
  {
    id: 'device-001',
    name: 'Conference Room A',
    co2: 680,
    temperature: 22.5,
    humidity: 45.2,
    occupancy: true,
    battery: 3250,
    lastUpdate: new Date().toISOString(),
  },
  {
    id: 'device-002',
    name: 'Office Wing B',
    co2: 520,
    temperature: 21.8,
    humidity: 42.1,
    occupancy: false,
    battery: 3100,
    lastUpdate: new Date().toISOString(),
  },
  {
    id: 'device-003',
    name: 'Meeting Room C',
    co2: 1150,
    temperature: 24.2,
    humidity: 48.5,
    occupancy: true,
    battery: 2980,
    lastUpdate: new Date().toISOString(),
  },
]

// Mock historical data for charts
const mockHistoricalData = [
  { time: '08:00', co2: 450, temp: 20.5, humidity: 40 },
  { time: '09:00', co2: 520, temp: 21.2, humidity: 42 },
  { time: '10:00', co2: 650, temp: 22.1, humidity: 44 },
  { time: '11:00', co2: 780, temp: 22.8, humidity: 45 },
  { time: '12:00', co2: 920, temp: 23.5, humidity: 46 },
  { time: '13:00', co2: 850, temp: 23.2, humidity: 45 },
  { time: '14:00', co2: 720, temp: 22.5, humidity: 44 },
  { time: '15:00', co2: 680, temp: 22.3, humidity: 43 },
]

function App() {
  const [selectedDevice] = useState(mockDevices[0])

  const getCO2Status = (co2: number) => {
    if (co2 < 800) return { label: 'Good', color: 'success' as const }
    if (co2 < 1000) return { label: 'Moderate', color: 'warning' as const }
    return { label: 'Poor', color: 'error' as const }
  }

  const getBatteryStatus = (voltage: number) => {
    if (voltage > 3000) return { label: 'Good', color: 'success' as const }
    if (voltage > 2600) return { label: 'Low', color: 'warning' as const }
    return { label: 'Critical', color: 'error' as const }
  }

  return (
    <Box sx={{ flexGrow: 1, minHeight: '100vh', bgcolor: '#f5f5f5' }}>
      {/* Header */}
      <AppBar position="static">
        <Toolbar>
          <AirOutlined sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            IoT MVP - Smart Building Dashboard
          </Typography>
          <Chip label="Live" color="success" size="small" />
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl" sx={{ mt: 4, mb: 4 }}>
        {/* Overview Cards */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center" mb={1}>
                  <AirOutlined color="primary" sx={{ mr: 1 }} />
                  <Typography variant="subtitle2" color="text.secondary">
                    Average CO₂
                  </Typography>
                </Box>
                <Typography variant="h4">
                  {Math.round(mockDevices.reduce((acc, d) => acc + d.co2, 0) / mockDevices.length)} ppm
                </Typography>
                <Chip
                  label={getCO2Status(680).label}
                  color={getCO2Status(680).color}
                  size="small"
                  sx={{ mt: 1 }}
                />
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center" mb={1}>
                  <ThermostatOutlined color="error" sx={{ mr: 1 }} />
                  <Typography variant="subtitle2" color="text.secondary">
                    Temperature
                  </Typography>
                </Box>
                <Typography variant="h4">
                  {(mockDevices.reduce((acc, d) => acc + d.temperature, 0) / mockDevices.length).toFixed(1)}°C
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Comfortable
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center" mb={1}>
                  <WaterDropOutlined color="info" sx={{ mr: 1 }} />
                  <Typography variant="subtitle2" color="text.secondary">
                    Humidity
                  </Typography>
                </Box>
                <Typography variant="h4">
                  {(mockDevices.reduce((acc, d) => acc + d.humidity, 0) / mockDevices.length).toFixed(1)}%
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Optimal
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center" mb={1}>
                  <PeopleOutline color="secondary" sx={{ mr: 1 }} />
                  <Typography variant="subtitle2" color="text.secondary">
                    Occupied Rooms
                  </Typography>
                </Box>
                <Typography variant="h4">
                  {mockDevices.filter(d => d.occupancy).length}/{mockDevices.length}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Active spaces
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Charts */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} md={8}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                CO₂ Levels - Last 8 Hours
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={mockHistoricalData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="co2"
                    stroke="#1976d2"
                    strokeWidth={2}
                    name="CO₂ (ppm)"
                  />
                </LineChart>
              </ResponsiveContainer>
            </Paper>
          </Grid>

          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Temperature & Humidity
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={mockHistoricalData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="temp"
                    stroke="#f44336"
                    strokeWidth={2}
                    name="Temp (°C)"
                  />
                  <Line
                    type="monotone"
                    dataKey="humidity"
                    stroke="#2196f3"
                    strokeWidth={2}
                    name="Humidity (%)"
                  />
                </LineChart>
              </ResponsiveContainer>
            </Paper>
          </Grid>
        </Grid>

        {/* Device List */}
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            All Devices
          </Typography>
          <Grid container spacing={2}>
            {mockDevices.map((device) => (
              <Grid item xs={12} md={4} key={device.id}>
                <Card variant="outlined">
                  <CardContent>
                    <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                      <Typography variant="h6">{device.name}</Typography>
                      {device.occupancy ? (
                        <Chip label="Occupied" color="primary" size="small" />
                      ) : (
                        <Chip label="Vacant" variant="outlined" size="small" />
                      )}
                    </Box>

                    <Box sx={{ mb: 1 }}>
                      <Box display="flex" justifyContent="space-between" mb={0.5}>
                        <Typography variant="body2" color="text.secondary">
                          CO₂
                        </Typography>
                        <Box display="flex" alignItems="center" gap={1}>
                          <Typography variant="body2" fontWeight="bold">
                            {device.co2} ppm
                          </Typography>
                          <Chip
                            label={getCO2Status(device.co2).label}
                            color={getCO2Status(device.co2).color}
                            size="small"
                          />
                        </Box>
                      </Box>

                      <Box display="flex" justifyContent="space-between" mb={0.5}>
                        <Typography variant="body2" color="text.secondary">
                          Temperature
                        </Typography>
                        <Typography variant="body2" fontWeight="bold">
                          {device.temperature}°C
                        </Typography>
                      </Box>

                      <Box display="flex" justifyContent="space-between" mb={0.5}>
                        <Typography variant="body2" color="text.secondary">
                          Humidity
                        </Typography>
                        <Typography variant="body2" fontWeight="bold">
                          {device.humidity}%
                        </Typography>
                      </Box>

                      <Box display="flex" justifyContent="space-between" alignItems="center">
                        <Typography variant="body2" color="text.secondary">
                          <BatteryFullOutlined sx={{ fontSize: 16, verticalAlign: 'middle', mr: 0.5 }} />
                          Battery
                        </Typography>
                        <Box display="flex" alignItems="center" gap={1}>
                          <Typography variant="body2" fontWeight="bold">
                            {device.battery} mV
                          </Typography>
                          <Chip
                            label={getBatteryStatus(device.battery).label}
                            color={getBatteryStatus(device.battery).color}
                            size="small"
                          />
                        </Box>
                      </Box>
                    </Box>

                    <Typography variant="caption" color="text.secondary">
                      Last update: {new Date(device.lastUpdate).toLocaleTimeString()}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Paper>

        {/* Footer */}
        <Box sx={{ mt: 4, mb: 2, textAlign: 'center' }}>
          <Typography variant="body2" color="text.secondary">
            IoT MVP - Smart Building Monitoring System v1.0.0
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Monitoring {mockDevices.length} devices | 18.2% HVAC energy savings
          </Typography>
        </Box>
      </Container>
    </Box>
  )
}

export default App
