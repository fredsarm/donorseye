const express = require('express');
const router = express.Router();

// GET all eve_access_tokens
router.get('/', (req, res) => {
  // Code to retrieve all records from the eve_access_tokens table in the database
  res.send('GET all eve_access_tokens');
});

// POST eve_access_tokens
router.post('/', (req, res) => {
  // Code to create a new record in the eve_access_tokens table in the database
  res.send('POST eve_access_tokens');
});

// PUT eve_access_tokens
router.put('/:id', (req, res) => {
  const id = req.params.id;
  // Code to update the record with the specified id in the eve_access_tokens table in the database
  res.send(`PUT eve_access_tokens by id: ${id}`);
});

// DELETE eve_access_tokens
router.delete('/:id', (req, res) => {
  const id = req.params.id;
  // Code to delete the record with the specified id from the eve_access_tokens table in the database
  res.send(`DELETE eve_access_tokens by id: ${id}`);
});

module.exports = router;
