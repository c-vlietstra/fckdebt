-- Users table: Core user data with hashed email/password and encrypted fields
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email_hash VARCHAR(255) UNIQUE NOT NULL,         -- Hashed with bcrypt
    password_hash VARCHAR(255) NOT NULL,             -- Hashed with bcrypt
    monthly_income_encrypted BYTEA DEFAULT NULL,     -- Encrypted with AES-256 (user key)
    budget_method VARCHAR(20) DEFAULT '50/20/30',    -- '50/20/30' or 'custom'
    fcm_token_encrypted BYTEA DEFAULT NULL,          -- Encrypted with AES-256 (user key)
    failed_attempts INTEGER DEFAULT 0,               -- Tracks login failures
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_method CHECK (budget_method IN ('50/20/30', 'custom'))
);

-- Web_sessions table: Temporary keys for web login
CREATE TABLE web_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    temp_key_encrypted BYTEA NOT NULL,               -- Temp AES-256 key, encrypted with permanent key
    expires_at TIMESTAMP NOT NULL,                   -- e.g., 24h expiry
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Budgets table: User's budget setup
CREATE TABLE budgets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    budget_method VARCHAR(20) NOT NULL,
    monthly_income_encrypted BYTEA NOT NULL,         -- Encrypted
    total_percentage DECIMAL NOT NULL DEFAULT 100,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_method CHECK (budget_method IN ('50/20/30', 'custom')),
    CONSTRAINT valid_percentage CHECK (total_percentage = 100)
);

-- Budget_splits table: Percentage-based budget allocations
CREATE TABLE budget_splits (
    id SERIAL PRIMARY KEY,
    budget_id INTEGER REFERENCES budgets(id),
    split_name_encrypted BYTEA NOT NULL,             -- Encrypted
    percentage DECIMAL NOT NULL,
    allocated_amount_encrypted BYTEA NOT NULL,       -- Encrypted
    CONSTRAINT valid_percentage CHECK (percentage >= 0 AND percentage <= 100)
);

-- Spending_categories table: Individual spending categories
CREATE TABLE spending_categories (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    category_name_encrypted BYTEA NOT NULL,          -- Encrypted
    budgeted_amount_encrypted BYTEA NOT NULL         -- Encrypted
);

-- Category_budget_splits table: Links categories to budget splits
CREATE TABLE category_budget_splits (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES spending_categories(id),
    budget_split_id INTEGER REFERENCES budget_splits(id),
    user_id INTEGER REFERENCES users(id)
);

-- Debts table: User's debt details
CREATE TABLE debts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    debt_name_encrypted BYTEA NOT NULL,              -- Encrypted
    current_balance_encrypted BYTEA NOT NULL,        -- Encrypted
    original_balance_encrypted BYTEA NOT NULL,       -- Encrypted
    interest_rate_encrypted BYTEA NOT NULL,          -- Encrypted
    min_payment_encrypted BYTEA NOT NULL,            -- Encrypted
    strategy VARCHAR(20) DEFAULT 'snowball',         -- 'snowball' or 'avalanche'
    start_date DATE NOT NULL,
    payoff_date DATE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Debt_payments table: Payment history for debts
CREATE TABLE debt_payments (
    id SERIAL PRIMARY KEY,
    debt_id INTEGER REFERENCES debts(id),
    user_id INTEGER REFERENCES users(id),
    payment_amount_encrypted BYTEA NOT NULL,         -- Encrypted
    payment_date DATE NOT NULL,
    remaining_balance_encrypted BYTEA NOT NULL       -- Encrypted
);

-- Accounts table: User's financial accounts
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    account_name_encrypted BYTEA NOT NULL,           -- Encrypted
    type VARCHAR(50) NOT NULL,                       -- e.g., 'Bank', 'Debt'
    balance_encrypted BYTEA NOT NULL,                -- Encrypted
    monthly_fees_encrypted BYTEA DEFAULT NULL,       -- Encrypted
    interest_rate_encrypted BYTEA DEFAULT NULL       -- Encrypted
);

-- Transactions table: Spending/income records
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    category_id INTEGER REFERENCES spending_categories(id),
    account_id INTEGER REFERENCES accounts(id),
    amount_encrypted BYTEA NOT NULL,                 -- Encrypted
    date DATE NOT NULL,
    description_encrypted BYTEA DEFAULT NULL         -- Encrypted
);

-- Goals table: Savings goals (e.g., F*ck-Off Fund)
CREATE TABLE goals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    goal_name_encrypted BYTEA NOT NULL,              -- Encrypted
    current_amount_encrypted BYTEA DEFAULT NULL,     -- Encrypted
    target_amount_encrypted BYTEA NOT NULL,          -- Encrypted
    monthly_contribution_encrypted BYTEA DEFAULT NULL,-- Encrypted
    is_active BOOLEAN DEFAULT TRUE
);

-- Notifications table: Push notification triggers
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    type VARCHAR(50) NOT NULL,                       -- e.g., 'debt_milestone'
    message_encrypted BYTEA NOT NULL,                -- Encrypted if sensitive
    trigger_value DECIMAL,
    is_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger to enforce budget_splits total percentage
CREATE OR REPLACE FUNCTION check_budget_splits_total()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT SUM(percentage) FROM budget_splits WHERE budget_id = NEW.budget_id) > 100 THEN
        RAISE EXCEPTION 'Total percentage for budget % exceeds 100', NEW.budget_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_budget_splits_total
BEFORE INSERT OR UPDATE ON budget_splits
FOR EACH ROW EXECUTE FUNCTION check_budget_splits_total();

-- Seed example data (encrypted fields would be populated by app)
INSERT INTO users (email_hash, password_hash, budget_method, failed_attempts) 
VALUES ('hashed_email_example', 'hashed_password_example', '50/20/30', 0);

INSERT INTO budgets (user_id, budget_method, monthly_income_encrypted, total_percentage) 
VALUES (1, '50/20/30', decode('encrypted_data', 'hex'), 100);

INSERT INTO budget_splits (budget_id, split_name_encrypted, percentage, allocated_amount_encrypted) 
VALUES 
    (1, decode('encrypted_needs', 'hex'), 50, decode('encrypted_1500', 'hex')),
    (1, decode('encrypted_savings', 'hex'), 20, decode('encrypted_600', 'hex')),
    (1, decode('encrypted_wants', 'hex'), 30, decode('encrypted_900', 'hex'));