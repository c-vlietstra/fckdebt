# Architecture

## Overview
F*ckDebt is a secure, privacy-first personal finance app built to help users crush debt and manage money like a grownup. It uses a client-server model with a Flutter mobile app (and future web support) as the frontend, a Node.js/Express backend, and a PostgreSQL database. All sensitive data is encrypted with a user-generated AES-256 key, ensuring zero-knowledge on the server side.

### System Diagram
```
+-------------------+       +-------------------+       +-------------------+
| Flutter Mobile App| <---> | Node.js/Express   | <---> | PostgreSQL DB     |
| (Client)          |       | (Backend)         |       | (Storage)         |
+-------------------+       +-------------------+       +-------------------+
| Web Browser       | <---> |                   |       |                   |
| (Future Client)   |       |                   |       |                   |
+-------------------+       +-------------------+       +-------------------+
```

## Components

### Frontend (Flutter Mobile App)
- **Tech**: Flutter (Dart)
- **Features**:
  - Debt tracking (snowball/avalanche strategies).
  - Budgeting (50/20/30 or custom).
  - Dashboard (net worth, accounts, goals).
  - Offline calculators (freedom number, debt payoff).
  - Secure key generation (`encrypt` package) and storage (`flutter_secure_storage`).
  - Push notification approval for web login.
- **Libraries**:
  - `encrypt`: AES-256 key generation/encryption.
  - `flutter_secure_storage`: Stores AES key.
  - `firebase_messaging`: Handles push notifications.
  - `provider`: State management.
  - `charts_flutter`: Visuals for debt progress.

### Backend (Node.js/Express)
- **Tech**: Node.js, Express, PostgreSQL (via `pg` module)
- **Features**:
  - REST API for data CRUD.
  - JWT authentication (short-lived tokens).
  - Decrypts/encrypts data with client-provided AES key.
  - Web login via push notification (FCM).
- **Libraries**:
  - `bcrypt`: Hashing email/password.
  - `crypto`: Temporary key generation for web.
  - `jsonwebtoken`: JWT handling.
  - `firebase-admin`: Push notifications.
  - `express-rate-limit`: Login attempt limits.

### Database (PostgreSQL)
- **Tech**: PostgreSQL v13+
- **Structure**: See [/docs/database.md](/docs/database.md)
- **Security**:
  - Sensitive fields encrypted as BYTEA with user’s AES-256 key.
  - Email/password hashed with bcrypt.
  - Temporary web session keys in `web_sessions`.
- **Features**:
  - Stores debts, budgets, accounts, transactions, goals, notifications.
  - Enforces budget percentage totals via triggers.

## Security
- **Key Management**: AES-256 key generated client-side, never stored on server.
- **Encryption**: All sensitive data encrypted with user’s key.
- **Authentication**: Hashed email/password; JWT for sessions; web login via mobile approval.
- **Fail-Safe**: 5 failed logins wipe mobile key.
- **Transmission**: HTTPS (TLS 1.3), HSTS enabled.

## Future Considerations
- **Web Client**: Browser support with temporary keys via mobile approval.
- **Offline Sync**: Queue API requests for when internet returns.
- **Scaling**: Add caching (Redis) for decrypted data if needed.
