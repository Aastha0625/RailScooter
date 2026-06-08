# PiScoot - Railway Scooter Fleet Management

Complete fleet management system for railway scooters with real-time GPS tracking, geofencing, alerts, and department/user assignments.

## Architecture

- **Frontend**: Flutter mobile app (iOS/Android)
- **Backend**: Node.js + Express REST API for all fleet data
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Cache**: Redis (optional, for real-time tracking)
- **Maps**: OpenStreetMap (Flutter app)

## Prerequisites

### Global
- Git
- Node.js 18+ (for backend)
- Flutter 3.0+ (for mobile app)
- Android Studio / Xcode (for mobile emulators)

### Accounts
- Supabase account (free tier available)
- No API keys needed — we use existing project keys

## Quick Start

### 1. Clone the Repository
```bash
git clone <repo-url>
cd project
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Configure environment (.env file already has keys)
# backend/.env contains:
# - SUPABASE_URL
# - SUPABASE_ANON_KEY
# - REDIS_URL (optional, gracefully falls back)
# - PORT=3000

# Start the backend server
npm start
# Server runs on http://localhost:3000

# For development with auto-reload
npm run dev
```

**Backend will be available at:**
- Health check: `http://localhost:3000/health`
- Vehicles API: `http://localhost:3000/api/vehicles`
- Departments API: `http://localhost:3000/api/departments`
- All endpoints: `/api/{vehicles,departments,users,assignments,alerts,tracking,stats}`

### 3. Flutter Mobile App Setup

```bash
cd flutter_app

# Get dependencies
flutter pub get

# Build & run on emulator/device
flutter run

# Or specify a device
flutter run -d chrome          # Web (experimental)
flutter run -d <device-id>     # Specific device
```

**First time setup:**
1. Have an Android emulator running OR iOS simulator
2. Run `flutter devices` to see available targets
3. Run `flutter run` — it will pick the first device

### 4. Testing the Full System

#### Terminal 1: Start Backend
```bash
cd backend
npm start
```

#### Terminal 2: Run Flutter App
```bash
cd flutter_app
flutter run
```

#### On App Launch
1. **Login Screen** appears — create an account with email/password
   - Email: `test@example.com`
   - Password: `password123`

2. **Dashboard** shows:
   - 5 pre-seeded vehicles (PS001, PSB002, PSA003, PS004, PSB005)
   - 5 departments (MECH, ELEC, OPS, SAFE, LOG)
   - 5 alert rules configured
   - 3 geofences (Main Station, Platform A, Maintenance Bay)

3. **Navigate** using the 6 main modules:
   - Vehicle Registry — browse/add/edit vehicles
   - Vehicle Registration — register new scooter
   - Department Assignment — manage dept/vehicle links
   - User Assignment — assign vehicles to operators
   - Alerts & Rules — configure alerts, view events
   - GeoFence & Tracking — live map, zone management

## Project Structure

```
project/
├── backend/
│   ├── src/
│   │   ├── server.js                 # Express app + WebSocket
│   │   ├── config/
│   │   │   ├── supabase.js          # Supabase client
│   │   │   └── redis.js             # Redis cache config
│   │   └── routes/
│   │       ├── vehicles.js          # Vehicle CRUD + search
│   │       ├── departments.js       # Department management
│   │       ├── users.js             # User profiles
│   │       ├── assignments.js       # Vehicle assignments
│   │       ├── alerts.js            # Alert rules & events
│   │       ├── tracking.js          # GPS tracking & geofences
│   │       └── stats.js             # Dashboard stats
│   ├── package.json
│   └── .env                         # Backend config
│
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart                # App entry + auth gate
│   │   ├── theme/
│   │   │   └── app_theme.dart       # Colors, typography
│   │   ├── models/
│   │   │   ├── vehicle.dart
│   │   │   ├── department.dart
│   │   │   ├── alert_rule.dart
│   │   │   └── geofence.dart
│   │   ├── services/
│   │   │   └── api_service.dart     # Authenticated Express API client
│   │   └── screens/
│   │       ├── auth/login_screen.dart
│   │       ├── dashboard/dashboard_screen.dart
│   │       ├── vehicles/
│   │       │   ├── vehicle_registry_screen.dart
│   │       │   ├── vehicle_registration_screen.dart
│   │       │   └── vehicle_details_sheet.dart
│   │       ├── departments/department_assignment_screen.dart
│   │       ├── users/user_assignment_screen.dart
│   │       ├── alerts/alerts_rules_screen.dart
│   │       └── tracking/geofence_tracking_screen.dart
│   ├── pubspec.yaml
│   └── android/, ios/, web/         # Platform-specific code
│
├── supabase/
│   └── migrations/                  # Database schema + seed data
│
└── README.md
```

## Database

### Schema
The Supabase database includes 8 tables with Row Level Security (RLS):

1. **departments** — Railway departments
2. **app_users** — Linked to Supabase auth, has department assignment
3. **vehicles** — Scooter registry with specs
4. **vehicle_assignments** — Active vehicle-department-user links
5. **alert_rules** — Configurable alert conditions
6. **vehicle_alerts** — Alert event log
7. **geofences** — GPS boundary zones
8. **vehicle_tracking** — Real-time location history

### Seeded Data
```
Vehicles:     PS001, PSB002, PSA003, PS004, PSB005
Departments:  MECH, ELEC, OPS, SAFE, LOG
Alert Rules:  Speed, Battery, Geofence, Idle Time, Movement
Geofences:    Main Station, Platform A Depot, Maintenance Bay
```

## Environment Variables

### Backend (`backend/.env`)
```
SUPABASE_URL=https://mskizgdxpcuuqzjlblou.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5c...
REDIS_URL=redis://localhost:6379
PORT=3000
JWT_SECRET=piscoot_jwt_secret_2024
```

### Flutter App
Hardcoded in `lib/main.dart` (same Supabase project):
```dart
await Supabase.initialize(
  url: 'https://mskizgdxpcuuqzjlblou.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1za2l6Z2R4cGN1dXF6amxibG91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDk0NzgsImV4cCI6MjA5NjQ4NTQ3OH0.gwAKQFhfeLMLUh4I1L4UUORv8hVQ1HzNvLTGQvs4ib4',
);
```

Flutter uses Supabase directly only for authentication. Fleet data requests go
through the Express backend and include the current Supabase access token.

The default backend URL is `http://10.0.2.2:3000` on an Android emulator and
`http://localhost:3000` on web and desktop. Override it for physical devices or
deployed environments:

```bash
flutter run --dart-define=BACKEND_HTTP_URL=http://192.168.1.10:3000
```

## API Endpoints

### Vehicles
```
GET    /api/vehicles?status=active&search=PS
GET    /api/vehicles/:id
POST   /api/vehicles           { vehicle_id, variant, battery_type, ... }
PUT    /api/vehicles/:id
DELETE /api/vehicles/:id
```

### Departments
```
GET    /api/departments
POST   /api/departments        { name, code, head_name, ... }
PUT    /api/departments/:id
DELETE /api/departments/:id
```

### Assignments
```
GET    /api/assignments
POST   /api/assignments        { vehicle_id, department_id, assigned_user_id }
DELETE /api/assignments/:id
```

### Alerts
```
GET    /api/alerts/rules
POST   /api/alerts/rules       { name, rule_type, severity, condition_value, ... }
PUT    /api/alerts/rules/:id
DELETE /api/alerts/rules/:id
GET    /api/alerts/events
PUT    /api/alerts/events/:id/acknowledge
```

### Tracking
```
GET    /api/tracking/live
GET    /api/tracking/:vehicleId/history
POST   /api/tracking           { vehicle_id, latitude, longitude, speed_kmh, ... }
GET    /api/tracking/geofences/all
POST   /api/tracking/geofences { name, center_lat, center_lng, radius_meters, ... }
DELETE /api/tracking/geofences/:id
```

### Stats
```
GET    /api/stats              { total_vehicles, active_vehicles, unacknowledged_alerts, ... }
```

## Running on Different Platforms

### Android Emulator
```bash
flutter run -d emulator-5554
```

### iOS Simulator
```bash
flutter run -d iPhone
```

### Web (Experimental)
```bash
flutter run -d chrome
```

### Physical Device
```bash
# USB debugging enabled
flutter run
```

## Troubleshooting

### Backend won't start
- Check if port 3000 is in use: `lsof -i :3000`
- Kill existing process: `kill -9 <PID>`
- Verify `.env` file exists with SUPABASE_URL

### Flutter won't compile
- Run `flutter doctor` to check setup
- Clean build: `flutter clean && flutter pub get && flutter run`
- Update Flutter: `flutter upgrade`

### Supabase auth fails
- Check email/password in login screen
- Verify Supabase project is active
- Check RLS policies are enabled (they are, by default)

### Map not loading
- Android: ensure Google Play Services installed in emulator
- iOS: ensure location permissions granted
- Check internet connectivity in emulator

### Redis cache errors (safe to ignore)
- Redis is optional, connection errors are logged but don't break the app
- Backend works fine without it — data comes from Supabase

## Performance Notes

- Vehicle list loads first 20, pagination supported
- Tracking updates cache every 5 seconds
- Department list cached 5 minutes
- Dashboard stats cached 1 minute
- Express forwards the authenticated user's Supabase token, so database access
  remains protected by RLS

## Security

- User authentication via Supabase email/password
- All database tables have RLS enabled
- Users can only access their own department's data
- Backend uses anon key (client-side auth enforced by RLS)
- Flutter uses Supabase directly only for authentication
- Flutter sends the Supabase access token to Express for fleet API requests

## Next Steps

1. **Customize branding**: Colors in `flutter_app/lib/theme/app_theme.dart`
2. **Add more fields**: Update database schema + models
3. **Deploy backend**: Heroku, Railway, or any Node.js host
4. **Submit to stores**: Build release APK/IPA

## Support

For issues or questions, refer to:
- Supabase docs: https://supabase.com/docs
- Flutter docs: https://flutter.dev/docs
- Express docs: https://expressjs.com
