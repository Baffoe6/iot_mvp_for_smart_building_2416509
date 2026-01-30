 Mobile App and Dashboard Design

 Overview

The IoT system provides two primary user interfaces:
1. Web Dashboard (React): For facilities managers at desktop workstations
2. Mobile App (React Native): For on-the-go monitoring and alert management

Both interfaces share the same REST API backend (AWS API Gateway) and authentication (AWS Cognito).

---

 User Personas

 Primary: Facilities Manager (Sarah)
- Role: Responsible for building operations, energy efficiency, occupant comfort
- Goals: Monitor air quality, respond to alerts, identify energy savings opportunities
- Context: Desktop during work hours (9-5), mobile app for after-hours alerts
- Technical proficiency: Moderate (comfortable with dashboards, not a developer)

 Secondary: Building Owner (James)
- Role: Reviews monthly energy reports, ROI on IoT investment
- Goals: Understand cost savings, sustainability metrics
- Context: Monthly review meetings, quarterly reports
- Technical proficiency: Low (prefers high-level summaries, PDF reports)

---

 Design Principles

1. Simplicity: No more than 4 main screens, clear navigation
2. Actionability: Every visualization should suggest a clear action (increase ventilation, replace battery, etc.)
3. Accessibility: WCAG 2.1 AA compliance (contrast, font sizes, screen reader support)
4. Performance: Dashboard refreshes in <5 seconds, mobile app works offline (cached data)
5. Responsiveness: Works on desktop (1920×1080), tablet (1024×768), mobile (375×667)

---

 Web Dashboard (Facilities Manager)

 Screen 1: Building Overview (Home)

Purpose: At-a-glance status of all monitored spaces

Layout:
```
┌─────────────────────────────────────────────────────────────────┐
│  Building A - Air Quality Dashboard           [User]  [Alerts]  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Summary Cards (Row 1)                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Rooms      │  │   Alerts    │  │  Battery   │          │
│  │              │  │              │  │              │          │
│  │    18/20     │  │      2       │  │  Low: 1      │          │
│  │   Online     │  │   Active     │  │  OK: 19      │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
│  Floor Plan (Interactive Map)                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Floor 2 - East Wing                    │  │
│  │                                                            │  │
│  │   [Room 201]   [Room 202]   [Room 203]   [Room 204]      │  │
│  │      🟢            🟡           🟢            🔴           │  │
│  │    820 ppm     1050 ppm     780 ppm     1350 ppm        │  │
│  │     22°C        23°C         21°C        25°C           │  │
│  │                                                            │  │
│  │   [Room 205]   [Meeting Rm] [Room 207]   [Room 208]      │  │
│  │      🟢            🟢           🟢            🟢           │  │
│  │                                                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Color Code:                                                    │
│  🟢 Good (<800 ppm)   🟡 Moderate (800-1000)                   │
│  🟠 Poor (1000-1200)  🔴 Alert (>1200 ppm)                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

Interactions:
- Click room: Navigate to Room Details screen
- Hover room: Show tooltip with last update time, occupancy status
- Color indicates CO₂ level: Red = immediate attention, Yellow = monitor, Green = OK

 Screen 2: Room Details

Purpose: Deep dive into a specific room's environmental conditions

Layout:
```
┌─────────────────────────────────────────────────────────────────┐
│  ← Back to Overview            Room 215 - Floor 2                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Current Conditions (Last updated: 2 minutes ago)                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ CO₂         │  │ Temperature │  │ Humidity    │            │
│  │ 850 ppm     │  │ 22.5°C      │  │ 45%         │            │
│  │ 🟢 Good      │  │ 🟢 Optimal   │  │ 🟢 OK        │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐                              │
│  │ Occupancy   │  │ Battery     │                              │
│  │ Occupied    │  │ 85%         │                              │
│  │ 👤 Yes       │  │  Good      │                              │
│  └─────────────┘  └─────────────┘                              │
│                                                                  │
│  Trends (Last 24 hours)                                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ CO₂ (ppm)                                                 │  │
│  │ 1400 ┤                                                    │  │
│  │ 1200 ┤                         ╭──────╮ Alert threshold  │  │
│  │ 1000 ┤           ╭────╮  ╭────╯      ╰────╮            │  │
│  │  800 ┤     ╭─────╯    ╰──╯                ╰───╮        │  │
│  │  600 ┤─────╯                                  ╰────    │  │
│  │  400 ┴───────────────────────────────────────────────  │  │
│  │      0h    6h    12h   18h   24h                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  [Temperature Chart] [Humidity Chart] [Occupancy Chart]         │
│  (Tabs to switch between metrics)                               │
│                                                                  │
│  Recent Alerts                                                  │
│  • 14:42 - High CO₂ (1350 ppm) - Resolved at 15:10             │
│  • 08:30 - High CO₂ (1280 ppm) - Resolved at 09:00             │
│                                                                  │
│  Actions                                                        │
│  [Configure Thresholds] [Download Report] [View Device Info]    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

Interactions:
- Time range selector: 24h, 7d, 30d (updates charts)
- Export button: Download CSV of all data points (for Excel analysis)
- Configure thresholds: Modal dialog to adjust CO₂/temp alert levels

 Screen 3: Alerts & Notifications

Purpose: Centralized view of all active and recent alerts

Layout:
```
┌─────────────────────────────────────────────────────────────────┐
│  Alerts & Notifications                        [Mark All Read]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Active Alerts (2)                                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 🔴 Room 215 - High CO₂                        2 min ago   │  │
│  │    Current: 1350 ppm  |  Threshold: 1200 ppm             │  │
│  │    Action: Increase ventilation or reduce occupancy       │  │
│  │    [View Room] [Acknowledge] [Snooze 1h]                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 🟠 sensor017 - Low Battery                   1 day ago    │  │
│  │    Current: 2.7V (18%)  |  Expected life: 4 weeks        │  │
│  │    Action: Schedule battery replacement                   │  │
│  │    [View Device] [Create Work Order] [Dismiss]            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Resolved Alerts (Last 7 days)                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Room 203 - High CO₂          Resolved 2 hours ago      │  │
│  │    Duration: 15 minutes  |  Peak: 1280 ppm               │  │
│  │    [View Details]                                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ... (list continues) ...                                        │
│                                                                  │
│  Notification Settings                                           │
│  ☑ Email notifications    ☑ SMS for critical alerts            │
│  ☑ Push notifications     ☐ Daily summary report              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

 Screen 4: Energy & Sustainability

Purpose: Show cost savings and environmental impact

Layout:
```
┌─────────────────────────────────────────────────────────────────┐
│  Energy & Sustainability Report          January 2026         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Key Metrics (This Month)                                        │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐      │
│  │ Energy Saved  │  │ Cost Saved    │  │ CO₂ Avoided   │      │
│  │               │  │               │  │               │      │
│  │   420 kWh     │  │    £126       │  │   180 kg      │      │
│  │  ↓ 18% vs.    │  │  ↓ 18% vs.    │  │  ↓ 18% vs.    │      │
│  │   baseline    │  │   baseline    │  │   baseline    │      │
│  └───────────────┘  └───────────────┘  └───────────────┘      │
│                                                                  │
│  Savings by Room (Top 5)                                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Room 204 ████████████████ 85 kWh (£25.50)              │  │
│  │ Room 215 ████████████ 62 kWh (£18.60)                  │  │
│  │ Meeting Room ██████ 48 kWh (£14.40)                     │  │
│  │ Room 201 ████ 35 kWh (£10.50)                           │  │
│  │ Room 208 ██ 22 kWh (£6.60)                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Occupancy-Based HVAC Control                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Hours with vacancy-driven setback: 1,245 hours           │  │
│  │ Average setback duration: 4.2 hours/day                  │  │
│  │ Estimated HVAC runtime reduction: 22%                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  [Download Monthly Report] [View ROI Calculator]                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

 Mobile App (iOS/Android, React Native)

 Screen 1: Dashboard (Home)

Purpose: Quick status check, respond to alerts on the go

Layout (Portrait, 375×667 iPhone SE):
```
┌──────────────────────────────────┐
│  Building A      🔔 (2)    ☰     │
├──────────────────────────────────┤
│                                  │
│  Summary                          │
│  ┌──────────────┬──────────────┐ │
│  │  Rooms      │  Alerts     │ │
│  │   18/20      │     2        │ │
│  │  Online      │  Active      │ │
│  └──────────────┴──────────────┘ │
│                                  │
│  Active Alerts                    │
│  ┌────────────────────────────┐  │
│  │ 🔴 Room 215 - High CO₂     │  │
│  │ 1350 ppm (limit: 1200)    │  │
│  │ 2 minutes ago              │  │
│  │                            │  │
│  │ [View Details]   [Dismiss] │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 🟠 sensor017 - Low Battery │  │
│  │ 18% remaining (4 weeks)   │  │
│  │ 1 day ago                  │  │
│  │                            │  │
│  │ [View Device]   [Dismiss]  │  │
│  └────────────────────────────┘  │
│                                  │
│  Quick Access                     │
│  [All Rooms] [Energy Report]     │
│  [Settings]  [Help & Support]    │
│                                  │
└──────────────────────────────────┘
```

Interactions:
- Bell icon (top right): Opens Alerts list
- Tap alert card: Navigate to Room Details
- Swipe alert card left: Quick dismiss
- Pull to refresh: Manually refresh data

 Screen 2: Room Details (Mobile)

Purpose: Simplified room view for mobile

Layout:
```
┌──────────────────────────────────┐
│  ← Room 215       Last update:   │
│                   2 min ago       │
├──────────────────────────────────┤
│                                  │
│  CO₂                              │
│  ┌────────────────────────────┐  │
│  │         850 ppm             │  │
│  │         🟢 Good             │  │
│  │                            │  │
│  │  ────────╮  ╭────          │  │
│  │        ╭─╯  ╰─╮            │  │
│  │   ─────╯      ╰──          │  │
│  │  (Last 6 hours)            │  │
│  └────────────────────────────┘  │
│                                  │
│  Temperature: 22.5°C  🟢          │
│  Humidity: 45%        🟢          │
│  Occupancy: Occupied  👤          │
│  Battery: 85%                   │
│                                  │
│  Recent Alerts                    │
│  • 14:42 High CO₂ (resolved)     │
│  • 08:30 High CO₂ (resolved)     │
│                                  │
│  [View Full History]              │
│  [Configure Alerts]               │
│                                  │
└──────────────────────────────────┘
```

 Screen 3: Alerts & Notifications (Mobile)

Purpose: Manage all alerts in one place

Layout:
```
┌──────────────────────────────────┐
│  ← Alerts         Mark All Read   │
├──────────────────────────────────┤
│                                  │
│  Active (2)                       │
│  ┌────────────────────────────┐  │
│  │ 🔴 Room 215                │  │
│  │ High CO₂: 1350 ppm        │  │
│  │ 2 min ago                  │  │
│  │                            │  │
│  │ [View]  [Ack]  [Snooze]   │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 🟠 sensor017               │  │
│  │ Low Battery: 18%          │  │
│  │ 1 day ago                  │  │
│  │                            │  │
│  │ [View]  [Dismiss]          │  │
│  └────────────────────────────┘  │
│                                  │
│  Resolved (7 days)                │
│  ┌────────────────────────────┐  │
│  │  Room 203 - High CO₂     │  │
│  │ Resolved 2 hours ago       │  │
│  └────────────────────────────┘  │
│                                  │
│  ... (list continues) ...         │
│                                  │
└──────────────────────────────────┘
```

---

 Accessibility Features (WCAG 2.1 AA)

 Visual Accessibility
- Color contrast: Minimum 4.5:1 for text, 3:1 for UI elements
- Color-blind safe palette: 
  - Good (green): 2E7D32
  - Moderate (yellow): F9A825
  - Poor (orange): EF6C00
  - Alert (red): C62828
  - Blue accent for neutral info: 1565C0
- Text alternatives: All icons have text labels (screen reader compatible)
- Font size: Minimum 14px body, 18px headings, scalable to 200% without breaking layout

 Motor Accessibility
- Touch targets: Minimum 44×44 px (iOS), 48×48 dp (Android)
- Keyboard navigation: All controls accessible via Tab, Enter, Space
- No time-based interactions: No auto-dismissing alerts or time-limited actions

 Cognitive Accessibility
- Simple language: "High CO₂" instead of "CO₂ concentration exceeds threshold by 12.5%"
- Progressive disclosure: Show summary first, "View Details" for deep dive
- Error prevention: Confirmation dialogs for destructive actions (e.g., "Delete alert history?")

 Screen Reader Support
- ARIA labels: All interactive elements have descriptive labels
- Semantic HTML: `<nav>`, `<main>`, `<article>` for proper structure
- Skip navigation links: "Skip to main content" for keyboard users

---

 Key User Journeys

 Journey 1: Respond to High CO₂ Alert

1. Push notification arrives on mobile: "High CO₂ in Room 215 (1350 ppm)"
2. Tap notification: Opens mobile app → Room 215 details
3. View chart: See CO₂ spiked at 14:42, occupancy shows 6 people in meeting
4. Take action: Call building engineer: "Increase ventilation in Room 215"
5. Monitor: Watch CO₂ trend down over next 15 minutes
6. Acknowledge alert: Tap "Acknowledge" → Alert marked as handled

Time: 3 minutes (from notification to action)

 Journey 2: Weekly Energy Review (Desktop)

1. Log in to web dashboard (Monday morning)
2. Navigate to "Energy & Sustainability" tab
3. Review last week's savings: £95 saved, 316 kWh reduction
4. Identify top performers: Room 204 saved most energy (85 kWh)
5. Download report: Click "Download Monthly Report" → PDF for leadership meeting
6. Share with building owner via email

Time: 5 minutes (weekly routine)

 Journey 3: Replace Low Battery

1. Daily email summary arrives: "sensor017 battery low (18%, 4 weeks remaining)"
2. Log in to dashboard, navigate to Alerts
3. Create work order: Click "Create Work Order" → Integration with CMMS (facility management software)
4. Work order auto-filled: Device ID, location (Room 207), priority (routine), due date (2 weeks)
5. Technician receives work order, replaces battery
6. Dashboard updates: Battery level 100%, alert auto-dismissed

Time: 2 minutes (manager), 15 minutes (technician)

---

 Wireframe Summary

All wireframes described above are text-based representations suitable for the report. For actual implementation:
- Design tool: Figma (collaborative, free tier adequate for MVP)
- Component library: Material-UI (React) or React Native Paper (mobile)
- Prototyping: Figma interactive prototype for user testing before development

---

 Related Documents

- [Security, Privacy & Sustainability](../implementation/security_privacy_sustainability.md) – Ethical considerations and threat model.
- [Test Plan](../../testing/test_plan.md) – Functional testing of dashboards and user acceptance criteria.
- [Mobile App Design](mobile_app_design.md) (this doc) – Technical specifications, API contracts, state management.
- [INDEX](../../INDEX.md) – Full document map and keyword search.
