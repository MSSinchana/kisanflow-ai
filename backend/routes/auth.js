const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const pool = require('../services/db');

const router = express.Router();

function signToken(user) {
  if (!process.env.JWT_SECRET) {
    throw new Error('JWT_SECRET is not configured');
  }

  return jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

router.post('/register', async (req, res) => {
  const { email, password, name, phone, village, district, farmerId } = req.body;

  if (!email || !password || !name || !phone || !village || !district || !farmerId) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [existingUsers] = await connection.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existingUsers.length > 0) {
      await connection.rollback();
      return res.status(409).json({ message: 'Email already registered' });
    }

    const [existingFarmers] = await connection.query('SELECT id FROM farmers WHERE farmer_id = ?', [farmerId]);
    if (existingFarmers.length > 0) {
      await connection.rollback();
      return res.status(409).json({ message: 'Farmer ID already registered' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const [userResult] = await connection.query(
      'INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)',
      [email, passwordHash, 'farmer']
    );

    await connection.query(
      'INSERT INTO farmers (user_id, farmer_id, name, phone, village, district) VALUES (?, ?, ?, ?, ?, ?)',
      [userResult.insertId, farmerId, name, phone, village, district]
    );

    await connection.commit();

    const token = signToken({ id: userResult.insertId, email, role: 'farmer' });
    return res.status(201).json({ token });
  } catch (error) {
    await connection.rollback();
    return res.status(500).json({ message: 'Registration failed', error: error.message });
  } finally {
    connection.release();
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  try {
    const [rows] = await pool.query('SELECT id, email, password_hash, role FROM users WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = rows[0];
    const passwordMatches = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatches) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = signToken(user);
    return res.json({ token });
  } catch (error) {
    return res.status(500).json({ message: 'Login failed', error: error.message });
  }
});

module.exports = router;
