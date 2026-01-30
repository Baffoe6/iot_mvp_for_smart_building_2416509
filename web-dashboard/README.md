 IoT MVP - Web Dashboard

React TypeScript dashboard for real-time monitoring of smart building air quality and occupancy.

 Quick Start

```bash
 Install dependencies
npm install

 Start development server
npm run dev

 Open browser to http://localhost:3000
```

 Features

✅ Real-time sensor data display (CO₂, temperature, humidity, occupancy)  
✅ Time-series charts for historical data  
✅ Device status monitoring with battery levels  
✅ Color-coded alerts (Good/Moderate/Poor air quality)  
✅ Responsive Material-UI design  
✅ Live data updates (currently using mock data)

 Current Status

Demo Mode: The dashboard currently displays mock data for demonstration purposes. To connect to real sensors:

1. Deploy AWS infrastructure: `cd ../cloud/terraform && terraform apply`
2. Configure environment variables in `.env` file
3. Implement API integration in `src/services/api.ts`
4. Connect to AWS IoT Core for real-time updates

 Project Structure

```
web-dashboard/
├── src/
│   ├── App.tsx               Main application component
│   ├── main.tsx              Application entry point
│   └── (components)          Individual UI components (coming)
├── index.html                HTML template
├── vite.config.ts           Vite configuration
├── package.json             Dependencies
└── README.md                This file
```

 Available Scripts

- `npm run dev` - Start development server (port 3000)
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm test` - Run tests

 Technologies

- React 18
- TypeScript
- Material-UI (MUI)
- Recharts (data visualization)
- Vite (build tool)
- AWS Amplify (AWS integration)

 Screenshots

The dashboard displays:
- Overview cards (average CO₂, temperature, humidity, occupied rooms)
- CO₂ trend chart (last 8 hours)
- Temperature & humidity chart
- Device cards with real-time status
- Color-coded health indicators

 Next Steps

1. Implement AWS API integration
2. Add user authentication (AWS Cognito)
3. Implement real-time MQTT subscription
4. Add alert management dashboard
5. Create floor plan view
6. Add energy savings reports

 License

Proprietary - IoT MVP Team, January 2026
