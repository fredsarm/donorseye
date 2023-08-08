import masterDetailQuery from '../queries/masterDetailQuery';
const schemaName = 'accounting';
const tableName = 'vw_eve_acc_entries';

export default async (req, res) => { // next.js is who will import it.
  await masterDetailQuery(req, res, schemaName, tableName); 
} 
