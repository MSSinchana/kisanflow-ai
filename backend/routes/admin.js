const express = require('express');

const router = express.Router();

router.get('/', (_req, res) => {
  res.json({ message: 'Admin API scaffold ready' });
});

module.exports = router;
