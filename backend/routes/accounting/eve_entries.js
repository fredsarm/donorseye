const express = require('express');
const router = express.Router();
const createSelectWhereAndOrder = require('../../sql_statements/selectWhereAndOrder');


router.get('/', async (req, res) => {
  await createSelectWhereAndOrder(req, res, 'accounting.eve_entries', [
    'entry_id',
    'entry_date',
    'occur_date',
    'acc_id',
    'entry_parent',
    'entity_id',
    'user_id',
    'memo',
    'debit',
    'credit',
    'balance']);
});

module.exports = router;
