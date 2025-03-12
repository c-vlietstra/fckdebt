const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db/pool');

const JWT_SECRET = process.env.JWT_SECRET;

const signup = async (req, res) => {
  const { email, password, monthly_income, budget_method, encrypted_data } = req.body;

  // Validate input
  if (!email || !password || !encrypted_data?.monthly_income) {
    return res.status(400).json({ error: 'Missing email, password, or encrypted monthly_income' });
  }

  try {
    // Hash email and password
    const emailHash = await bcrypt.hash(email, 12);
    const passwordHash = await bcrypt.hash(password, 12);

    // Insert user into database
    const result = await pool.query(
      `INSERT INTO users (email_hash, password_hash, monthly_income_encrypted, budget_method)
       VALUES ($1, $2, decode($3, 'hex'), $4) RETURNING id`,
      [emailHash, passwordHash, encrypted_data.monthly_income, budget_method || '50/20/30']
    );

    const userId = result.rows[0].id;

    // Generate JWT
    const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '1h' });

    res.status(200).json({ user_id: userId, token });
  } catch (error) {
    if (error.code === '23505') { // Unique violation (email_hash)
      return res.status(409).json({ error: 'Email already registered' });
    }
    console.error(error);
    res.status(500).json({ error: 'Server error during signup' });
  }
};

module.exports = { signup };