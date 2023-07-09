const express = require('express');
const router = express.Router();

// GET all eve_refresh_tokens
router.get('/', (req, res) => {
  // Code to retrieve all records from the eve_refresh_tokens table in the database
  res.send('GET all eve_refresh_tokens');
});

// POST eve_refresh_tokens
router.post('/', (req, res) => {
  // Code to create a new record in the eve_refresh_tokens table in the database
  res.send('POST eve_refresh_tokens');
});

// PUT eve_refresh_tokens
router.put('/:id', (req, res) => {
  const id = req.params.id;
  // Code to update the record with the specified id in the eve_refresh_tokens table in the database
  res.send(`PUT eve_refresh_tokens by id: ${id}`);
});

// DELETE eve_refresh_tokens
router.delete('/:id', (req, res) => {
  const id = req.params.id;
  // Code to delete the record with the specified id from the eve_refresh_tokens table in the database
  res.send(`DELETE eve_refresh_tokens by id: ${id}`);
});

module.exports = router;
