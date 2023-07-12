const express = require('express');
const router = express.Router();
const pgp = require('pg-promise')();
const db = require('../../db_connections/accConnection.js');

// Rota GET para recuperar dados da tabela eve_entries
router.get('/', async (req, res) => {
  try {
    let {

      selCols,

      whereCol1,
      compOp1,
      whereVal1,

      logOp1,
      whereCol2,
      compOp2,
      whereVal2,

      orbyCol1,
      dir1,

      orbyCol2,
      dir2,

    } = req.query;

// Define the allowed options for each parameter

    const tabName = 'accounting.eve_entries';

    const allowCols = ['entry_id', 'entry_date', 'occur_date', 'acc_id', 'entry_parent', 'entity_id', 'user_id', 'memo', 'debit', 'credit', 'balance']; // Add your allowed columns here
    const allowCompOps = ['=', '>', '<', '<>','ILIKE','NOT ILIKE'];
    const allowLogOps = ['AND','OR','NOT'];
    const allowDirs = ['ASC', 'DESC'];

    let partWhere1;
    let partWhere2;

    let orBy1;
    let orBy2;

    let howManyWhere;
    let howManyOrBy;

// WHERE CLAUSES creation

if (
  allowCols.includes(whereCol1) &&
  allowCompOps.includes(compOp1) &&
  whereVal1
)
{
  partWhere1 = ` WHERE ${whereCol1} ${compOp1} $1`;
  howManyWhere= 'w1';
  if (
    allowLogOps.includes(logOp1) &&
    allowCols.includes(whereCol2) &&
    allowCompOps.includes(compOp2) &&
    whereVal2
  )
  {
    partWhere2 = ` ${logOp1} ${whereCol2} ${compOp2} $2`;
    howManyWhere= 'w2';
  }
}

// ORDER BY clauses creation

if (
  allowCols.includes(orbyCol1) &&
  allowDirs.includes(dir1)
)
{
  orBy1 = ` ${orbyCol1} ${dir1}`;
  howManyOrBy = 'o1';

  if (
  allowCols.includes(orbyCol2) &&
  allowDirs.includes(dir2)
  )
  {
    orBy2 = `, ${orbyCol2} ${dir2}`;
    howManyOrBy = 'o2';
  }
}

// SELECT columns creation

if (!selCols) {
    SelCols = '*'
}

let query;
let switchCase = '';

if (howManyWhere) {
  switchCase += howManyWhere;
}
if (howManyOrBy) {
  switchCase += howManyOrBy;
}

switch(switchCase) {

  case 'w1':
    query = pgp.as.format(
      'SELECT ' + selCols + ' FROM ' + tabName + ' ' + partWhere1,
      [whereVal1]
    );
    console.log ('w1')
        break;

  case 'w2':
    query = pgp.as.format(
      'SELECT ' + selCols + ' FROM ' + tabName + ' ' + partWhere1 + partWhere2,
      [whereVal1, whereVal2]
    );
    console.log ('w2')
        break;

  case 'w1o1':
    query = pgp.as.format(
      'SELECT ' + selCols + ' FROM ' + tabName + ' ' + partWhere1 + orBy1,
      [whereVal1]
    );
    console.log ('w1o1')
        break;

  case 'w2o1':
    query = pgp.as.format(
      'SELECT ' + selCols + ' FROM ' + tabName + ' ' + partWhere1 + partWhere2 + orBy1,
      [whereVal1, whereVal2]
    );
    console.log ('w2o1')
        break;

  case 'w2o2':
    query = pgp.as.format(
      'SELECT ' + selCols + ' FROM ' + tabName + ' ' + partWhere1 + partWhere2 + orBy1 + ' ' + orBy2,
      [whereVal1, whereVal2]
    );
    console.log ('w2o2')
        break;

  case 'o1':
    query = pgp.as.format(
      'SELECT ' + selCols + ' FROM ' + tabName + ' ' + orBy1,
    );
    console.log ('o1')
        break;

  case 'o2':
    query = pgp.as.format(
      'SELECT ' + selCols + ' FROM ' + tabName + ' ' + orBy1 + ' ' + orBy2,
    );
    console.log ('o2')
        break;

  default:
    query = pgp.as.format(
      'SELECT ' + selCols + ' FROM ' + tabName
    );
}
console.log(query);
console.log(`whereCol1: ${whereCol1}`);
console.log(`compOp1: ${compOp1}`);
console.log(`whereVal1: ${whereVal1}`);

    // Execução da consulta no banco de dados
    const data = await db.any(query);

    res.json(data);
  } catch (error) {
    console.error('Error retrieving data:', error);
    res.status(500).send('Internal Server Error');
  }
});

module.exports = router;
