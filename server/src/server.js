require('dotenv').config();
const express = require('express');
const rateLimit = require('express-rate-limit');
const authRoutes = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // 100 requests per IP
}));

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'F*ckDebt Server v1 - Ready to crush debt!' });
});
app.use('/v1/auth', authRoutes);

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});