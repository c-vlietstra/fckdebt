# API Documentation for F*ckDebt

## Overview
The F*ckDebt API is a RESTful interface built with Node.js/Express, serving the Flutter mobile app (and future web client). All endpoints require a JWT `Bearer` token in the header (except signup and initial login). Inputs are JSON in the request body, and sensitive data is encrypted/decrypted with a client-provided AES key (`aes_key` for mobile, `temp_key` for web). Calculators run offline in the app, not via API.

## Base URL
`https://api.fckdebt.com`

## Authentication
All endpoints except `/api/auth/signup` and `/api/auth/login` require a JWT token.

### POST /api/auth/signup
- **Description**: Register a new user; client generates AES key.
- **Request**:
  ```json
  {
    "email": "string",
    "password": "string",
    "monthly_income": "number",
    "budget_method": "string",
    "encrypted_data": { "monthly_income": "hex" }
  }
  ```
- **Response (200 OK)**:
  ```json
  { "user_id": "number", "token": "string" }
  ```
- **Errors**:
  - **400 Bad Request**: `Invalid email or password format`
  - **409 Conflict**: `Email already registered`
  - **500 Internal Server Error**: `Server error during signup`

### POST /api/auth/login (Mobile)
- **Description**: Mobile login with permanent AES key.
- **Request**:
  ```json
  {
    "email": "string",
    "password": "string",
    "aes_key": "hex"
  }
  ```
- **Response (200 OK)**:
  ```json
  { "user_id": "number", "token": "string" }
  ```
- **Errors**:
  - **400 Bad Request**: `Missing email, password, or aes_key`
  - **401 Unauthorized**: `Invalid credentials` (+ `attempts`)
  - **403 Forbidden**: `Too many failed attempts; key reset required`
  - **500 Internal Server Error**: `Server error during login`

### POST /api/auth/login/web
- **Description**: Initiate web login; triggers mobile push.
- **Request**:
  ```json
  { "email": "string", "password": "string" }
  ```
- **Response (202 Accepted)**:
  ```json
  { "message": "Push notification sent to mobile" }
  ```
- **Errors**:
  - **400 Bad Request**: `Missing email or password`
  - **401 Unauthorized**: `Invalid credentials`
  - **404 Not Found**: `No mobile device registered`
  - **500 Internal Server Error**: `Failed to send push notification`

### POST /api/auth/web/approve
- **Description**: Mobile approves web login; returns temp key.
- **Request**:
  ```json
  { "user_id": "number", "aes_key": "hex" }
  ```
- **Response (200 OK)**:
  ```json
  { "user_id": "number", "token": "string", "temp_key": "hex" }
  ```
- **Errors**:
  - **400 Bad Request**: `Missing user_id or aes_key`
  - **403 Forbidden**: `Unauthorized approval attempt`
  - **500 Internal Server Error**: `Server error during web approval`

## Debt Management

### POST /api/debts/list
- **Description**: Get all debts for a user.
- **Request**:
  ```json
  { "user_id": "number", "aes_key": "hex" }
  ```
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "number",
      "debt_name": "string",
      "current_balance": "number",
      "original_balance": "number",
      "interest_rate": "number",
      "min_payment": "number",
      "strategy": "string",
      "start_date": "string",
      "payoff_date": "string",
      "is_active": "boolean"
    }
  ]
  ```
- **Errors**:
  - **400 Bad Request**: `Missing user_id or aes_key`
  - **401 Unauthorized**: `Invalid token`
  - **403 Forbidden**: `Invalid decryption key`
  - **500 Internal Server Error**: `Server error retrieving debts`

### POST /api/debts/create
- **Description**: Add a new debt.
- **Request**:
  ```json
  {
    "user_id": "number",
    "aes_key": "hex",
    "debt_name": "string",
    "current_balance": "number",
    "original_balance": "number",
    "interest_rate": "number",
    "min_payment": "number",
    "start_date": "string",
    "strategy": "string"
  }
  ```
- **Response (201 Created)**:
  ```json
  { "id": "number", "debt_name": "string", ... }
  ```
- **Errors**:
  - **400 Bad Request**: `Invalid debt data`
  - **401 Unauthorized**: `Invalid token`
  - **500 Internal Server Error**: `Server error creating debt`

### POST /api/debts/update
- **Description**: Update an existing debt.
- **Request**:
  ```json
  {
    "user_id": "number",
    "aes_key": "hex",
    "debt_id": "number",
    "current_balance": "number",
    "strategy": "string",
    ...
  }
  ```
- **Response (200 OK)**:
  ```json
  { "id": "number", "current_balance": "number", ... }
  ```
- **Errors**:
  - **400 Bad Request**: `Missing debt_id or updates`
  - **401 Unauthorized**: `Invalid token`
  - **404 Not Found**: `Debt not found`
  - **500 Internal Server Error**: `Server error updating debt`

### POST /api/debts/payment
- **Description**: Record a debt payment.
- **Request**:
  ```json
  {
    "user_id": "number",
    "aes_key": "hex",
    "debt_id": "number",
    "payment_amount": "number",
    "payment_date": "string"
  }
  ```
- **Response (201 Created)**:
  ```json
  { "id": "number", "remaining_balance": "number" }
  ```
- **Errors**:
  - **400 Bad Request**: `Invalid payment data`
  - **401 Unauthorized**: `Invalid token`
  - **404 Not Found**: `Debt not found`
  - **500 Internal Server Error**: `Server error recording payment`

## Budgeting

### POST /api/budget/get
- **Description**: Fetch user’s budget.
- **Request**:
  ```json
  { "user_id": "number", "aes_key": "hex" }
  ```
- **Response (200 OK)**:
  ```json
  {
    "budget_method": "string",
    "monthly_income": "number",
    "splits": [
      {
        "split_name": "string",
        "percentage": "number",
        "allocated_amount": "number",
        "categories": [
          { "category_name": "string", "budgeted_amount": "number" }
        ]
      }
    ]
  }
  ```
- **Errors**:
  - **400 Bad Request**: `Missing user_id or aes_key`
  - **401 Unauthorized**: `Invalid token`
  - **403 Forbidden**: `Invalid decryption key`
  - **404 Not Found**: `Budget not found`

### POST /api/budget/create
- **Description**: Create a new budget.
- **Request**:
  ```json
  {
    "user_id": "number",
    "aes_key": "hex",
    "budget_method": "string",
    "monthly_income": "number",
    "splits": [
      {
        "split_name": "string",
        "percentage": "number",
        "categories": [
          { "name": "string", "amount": "number" }
        ]
      }
    ]
  }
  ```
- **Response (201 Created)**:
  ```json
  { "budget_id": "number", ... }
  ```
- **Errors**:
  - **400 Bad Request**: `Invalid budget data or percentages`
  - **401 Unauthorized**: `Invalid token`
  - **500 Internal Server Error**: `Server error creating budget`

### POST /api/budget/update
- **Description**: Update an existing budget.
- **Request**:
  ```json
  {
    "user_id": "number",
    "aes_key": "hex",
    "budget_id": "number",
    "monthly_income": "number",
    "splits": [
      { "id": "number", "percentage": "number", "categories": [...] }
    ]
  }
  ```
- **Response (200 OK)**:
  ```json
  { "budget_id": "number", ... }
  ```
- **Errors**:
  - **400 Bad Request**: `Invalid budget update data`
  - **401 Unauthorized**: `Invalid token`
  - **404 Not Found**: `Budget not found`

## Dashboard

### POST /api/dashboard/get
- **Description**: Fetch dashboard data.
- **Request**:
  ```json
  { "user_id": "number", "aes_key": "hex" }
  ```
- **Response (200 OK)**:
  ```json
  {
    "net_worth": "number",
    "accounts": [
      { "id": "number", "account_name": "string", "balance": "number", ... }
    ],
    "goals": [
      { "id": "number", "goal_name": "string", "current_amount": "number", ... }
    ]
  }
  ```
- **Errors**:
  - **400 Bad Request**: `Missing user_id or aes_key`
  - **401 Unauthorized**: `Invalid token`
  - **403 Forbidden**: `Invalid decryption key`

### POST /api/accounts/create
- **Description**: Add a new account.
- **Request**:
  ```json
  {
    "user_id": "number",
    "aes_key": "hex",
    "account_name": "string",
    "type": "string",
    "balance": "number"
  }
  ```
- **Response (201 Created)**:
  ```json
  { "id": "number", ... }
  ```
- **Errors**:
  - **400 Bad Request**: `Invalid account data`
  - **401 Unauthorized**: `Invalid token`

### POST /api/goals/create
- **Description**: Add a new savings goal.
- **Request**:
  ```json
  {
    "user_id": "number",
    "aes_key": "hex",
    "goal_name": "string",
    "target_amount": "number",
    "monthly_contribution": "number"
  }
  ```
- **Response (201 Created)**:
  ```json
  { "id": "number", ... }
  ```
- **Errors**:
  - **400 Bad Request**: `Invalid goal data`
  - **401 Unauthorized**: `Invalid token`

## Transactions

### POST /api/transactions/create
- **Description**: Record a transaction.
- **Request**:
  ```json
  {
    "user_id": "number",
    "aes_key": "hex",
    "category_id": "number",
    "account_id": "number",
    "amount": "number",
    "date": "string",
    "description": "string"
  }
  ```
- **Response (201 Created)**:
  ```json
  { "id": "number", ... }
  ```
- **Errors**:
  - **400 Bad Request**: `Invalid transaction data`
  - **401 Unauthorized**: `Invalid token`
  - **404 Not Found**: `Category or account not found`

### POST /api/transactions/list
- **Description**: Get transaction history.
- **Request**:
  ```json
  { "user_id": "number", "aes_key": "hex" }
  ```
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "number",
      "amount": "number",
      "category_name": "string",
      "account_name": "string",
      "date": "string",
      "description": "string"
    }
  ]
  ```
- **Errors**:
  - **400 Bad Request**: `Missing user_id or aes_key`
  - **401 Unauthorized**: `Invalid token`
  - **403 Forbidden**: `Invalid decryption key`

## Notifications

### POST /api/notifications/list
- **Description**: Get notification triggers.
- **Request**:
  ```json
  { "user_id": "number", "aes_key": "hex" }
  ```
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "number",
      "type": "string",
      "message": "string",
      "trigger_value": "number",
      "is_sent": "boolean"
    }
  ]
  ```
- **Errors**:
  - **400 Bad Request**: `Missing user_id or aes_key`
  - **401 Unauthorized**: `Invalid token`
  - **403 Forbidden**: `Invalid decryption key`

### POST /api/notifications/create
- **Description**: Add a notification trigger.
- **Request**:
  ```json
  {
    "user_id": "number",
    "aes_key": "hex",
    "type": "string",
    "message": "string",
    "trigger_value": "number"
  }
  ```
- **Response (201 Created)**:
  ```json
  { "id": "number", ... }
  ```
- **Errors**:
  - **400 Bad Request**: `Invalid notification data`
  - **401 Unauthorized**: `Invalid token`

## Notes
- **AES Key**: Mobile uses permanent `aes_key`; web uses `temp_key` from `web_sessions`.
- **Encryption**: Client encrypts sensitive data; server decrypts with provided key for responses.
- **Offline**: Calculators (e.g., freedom number) run in Flutter, not via API.
