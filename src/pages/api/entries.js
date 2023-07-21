import { query } from '../../connections/conns';

export default async (req, res) => {
  const result = await query('SELECT * FROM accounting.vw_eve_entries where entry_id <30000 order by memo');
  res.json(result);
};
 
