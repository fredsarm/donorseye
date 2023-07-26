// src/pages/api/entries.js

import mainQuery from '../../queries/mainQuery';

const schemaName = 'accounting';
const tableName = 'vw_eve_entries';

export default async (req, res) => { // next.js will import it
  try {
    const result = await mainQuery(req,schemaName,tableName);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}; 