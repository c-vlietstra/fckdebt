# Architecture

## Overview
F*ckDebt uses a client-server setup: Flutter frontend, Node.js/Express backend, PostgreSQL database.

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Node.js/Express (REST API)
- **Database**: PostgreSQL

### System Diagram
+-------------------+       +-------------------+       +-------------------+
|   Flutter Mobile  | <---> |  Node.js/Express  | <---> |   PostgreSQL DB   |
|      (Client)     |       |     (Backend)     |       |    (Storage)      |
+-------------------+       +-------------------+       +-------------------+

### Components
- **Frontend**: Screens for debt, dashboard, budgeting, calculators; Provider for state; `charts_flutter` for visuals.
- **Backend**: API endpoints for auth, debts, budgeting, goals; logic for calculations (e.g., snowball/avalanche).
- **Database**: Tables for users, debts, accounts, transactions, goals.