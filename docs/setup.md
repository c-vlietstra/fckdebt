# Setup Instructions

## Prerequisites
- Node.js (v16+)
- PostgreSQL (v13+)
- Flutter (v3+)
- Dart (Flutter-compatible version)

## Backend
1. `cd fckdebt/server`
2. `npm install`
3. Configure `.env`:
```
PORT=3000
DATABASE_URL=postgres://user:password@localhost:5432/fckdebt
JWT_SECRET=your-secret-here
FCM_SERVER_KEY=your-fcm-key
```
See `.env.example` for details.
4. Run database: `psql -f docs/sql/schema.sql`
5. Start: `npm start`

## Frontend (Flutter Mobile)
1. `cd fckdebt/mobile`
2. `flutter pub get`
- Dependencies: `encrypt`, `flutter_secure_storage`, `firebase_messaging`, `provider`, `charts_flutter`
3. Configure Firebase for push notifications (see `firebase_messaging` docs).
4. Run: `flutter run`

## Notes
- Ensure PostgreSQL is running before starting the backend.
- Flutter app generates AES-256 key on signup—save it locally for testing.