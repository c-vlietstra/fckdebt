# Database Design for F*ckDebt

## Overview
F*ckDebt uses PostgreSQL to store user data, debts, budgets, and more, with a focus on security and privacy. Sensitive data is encrypted with a user-generated AES-256 key (never stored on the server), and PII (email) is hashed. The schema supports mobile and web logins, budgeting (50/20/30 or custom), and all core features while ensuring data integrity and normalization.

## Schema

### Tables

1. **users**
   - `id` (SERIAL PRIMARY KEY)
   - `email_hash` (VARCHAR(255) UNIQUE NOT NULL): Hashed email (bcrypt)
   - `password_hash` (VARCHAR(255) NOT NULL): Hashed password (bcrypt)
   - `monthly_income_encrypted` (BYTEA DEFAULT NULL): Encrypted with user’s AES-256 key
   - `budget_method` (VARCHAR(20) DEFAULT '50/20/30'): ‘50/20/30’ or ‘custom’
   - `fcm_token_encrypted` (BYTEA DEFAULT NULL): Encrypted FCM token
   - `failed_attempts` (INTEGER DEFAULT 0): Tracks login failures
   - `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

2. **web_sessions**
   - `id` (SERIAL PRIMARY KEY)
   - `user_id` (INTEGER REFERENCES users(id))
   - `temp_key_encrypted` (BYTEA NOT NULL): Temporary AES key for web, encrypted with permanent key
   - `expires_at` (TIMESTAMP NOT NULL): Session expiry (e.g., 24h)
   - `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

3. **budgets**
   - `id` (SERIAL PRIMARY KEY)
   - `user_id` (INTEGER REFERENCES users(id))
   - `budget_method` (VARCHAR(20) NOT NULL)
   - `monthly_income_encrypted` (BYTEA NOT NULL): Encrypted
   - `total_percentage` (DECIMAL NOT NULL DEFAULT 100)
   - `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

4. **budget_splits**
   - `id` (SERIAL PRIMARY KEY)
   - `budget_id` (INTEGER REFERENCES budgets(id))
   - `split_name_encrypted` (BYTEA NOT NULL): Encrypted (e.g., “Needs”)
   - `percentage` (DECIMAL NOT NULL): e.g., 50, 20, 30
   - `allocated_amount_encrypted` (BYTEA NOT NULL): Encrypted (income * percentage / 100)

5. **spending_categories**
   - `id` (SERIAL PRIMARY KEY)
   - `user_id` (INTEGER REFERENCES users(id))
   - `category_name_encrypted` (BYTEA NOT NULL): Encrypted
   - `budgeted_amount_encrypted` (BYTEA NOT NULL): Encrypted

6. **category_budget_splits**
   - `id` (SERIAL PRIMARY KEY)
   - `category_id` (INTEGER REFERENCES spending_categories(id))
   - `budget_split_id` (INTEGER REFERENCES budget_splits(id))
   - `user_id` (INTEGER REFERENCES users(id))

7. **debts**
   - `id` (SERIAL PRIMARY KEY)
   - `user_id` (INTEGER REFERENCES users(id))
   - `debt_name_encrypted` (BYTEA NOT NULL): Encrypted
   - `current_balance_encrypted` (BYTEA NOT NULL): Encrypted
   - `original_balance_encrypted` (BYTEA NOT NULL): Encrypted
   - `interest_rate_encrypted` (BYTEA NOT NULL): Encrypted
   - `min_payment_encrypted` (BYTEA NOT NULL): Encrypted
   - `strategy` (VARCHAR(20) DEFAULT 'snowball'): ‘snowball’ or ‘avalanche’
   - `start_date` (DATE NOT NULL)
   - `payoff_date` (DATE)
   - `is_active` (BOOLEAN DEFAULT TRUE)

8. **debt_payments**
   - `id` (SERIAL PRIMARY KEY)
   - `debt_id` (INTEGER REFERENCES debts(id))
   - `user_id` (INTEGER REFERENCES users(id))
   - `payment_amount_encrypted` (BYTEA NOT NULL): Encrypted
   - `payment_date` (DATE NOT NULL)
   - `remaining_balance_encrypted` (BYTEA NOT NULL): Encrypted

9. **accounts**
   - `id` (SERIAL PRIMARY KEY)
   - `user_id` (INTEGER REFERENCES users(id))
   - `account_name_encrypted` (BYTEA NOT NULL): Encrypted
   - `type` (VARCHAR(50) NOT NULL): e.g., ‘Bank’, ‘Debt’
   - `balance_encrypted` (BYTEA NOT NULL): Encrypted
   - `monthly_fees_encrypted` (BYTEA DEFAULT NULL): Encrypted
   - `interest_rate_encrypted` (BYTEA DEFAULT NULL): Encrypted

10. **transactions**
    - `id` (SERIAL PRIMARY KEY)
    - `user_id` (INTEGER REFERENCES users(id))
    - `category_id` (INTEGER REFERENCES spending_categories(id))
    - `account_id` (INTEGER REFERENCES accounts(id))
    - `amount_encrypted` (BYTEA NOT NULL): Encrypted
    - `date` (DATE NOT NULL)
    - `description_encrypted` (BYTEA DEFAULT NULL): Encrypted

11. **goals**
    - `id` (SERIAL PRIMARY KEY)
    - `user_id` (INTEGER REFERENCES users(id))
    - `goal_name_encrypted` (BYTEA NOT NULL): Encrypted
    - `current_amount_encrypted` (BYTEA DEFAULT NULL): Encrypted
    - `target_amount_encrypted` (BYTEA NOT NULL): Encrypted
    - `monthly_contribution_encrypted` (BYTEA DEFAULT NULL): Encrypted
    - `is_active` (BOOLEAN DEFAULT TRUE)

12. **notifications**
    - `id` (SERIAL PRIMARY KEY)
    - `user_id` (INTEGER REFERENCES users(id))
    - `type` (VARCHAR(50) NOT NULL): e.g., ‘debt_milestone’
    - `message_encrypted` (BYTEA NOT NULL): Encrypted if sensitive
    - `trigger_value` (DECIMAL)
    - `is_sent` (BOOLEAN DEFAULT FALSE)
    - `created_at` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

## Notes
- **Encryption**: Sensitive fields are encrypted with a user-generated AES-256 key (client-side, never stored on server). Stored as BYTEA.
- **Hashing**: `email_hash` and `password_hash` use bcrypt for secure authentication.
- **Web Login**: `web_sessions` supports temporary keys for browser access, approved via mobile push notification.
- **Budgeting**: `budgets`, `budget_splits`, and `category_budget_splits` enforce percentage-based allocations (e.g., 50/20/30).
- **Fail-Safe**: `failed_attempts` triggers key deletion after 5 failed logins on mobile.
- **Setup**: Run `schema.sql` to initialize; encrypted data is populated by the app.

## Validation
- Trigger on `budget_splits` ensures `SUM(percentage)` ≤ 100 per `budget_id`.