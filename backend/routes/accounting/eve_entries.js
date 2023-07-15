const express = require('express');
const router = express.Router();
const queryFilteredAndOrdered = require('../../queries/queryFilteredAndOrdered');

const schemaName = 'accounting';
const tableName = 'eve_entries';
const viewName = 'vw_eve_entries';

router.get('/', async (req, res) => {
  await queryFilteredAndOrdered(req, res,schemaName,tableName, viewName);
});

module.exports = router;
