// src/connections/accountingConn.js 
const pg = require('pg');
pg.types.setTypeParser(pg.types.builtins.TIMESTAMPTZ, value => value);
pg.types.setTypeParser(pg.types.builtins.TIMESTAMP, value => value);
pg.types.setTypeParser(pg.types.builtins.DATE, value => value);
pg.types.setTypeParser(pg.types.builtins.NUMERIC, value => value);

const pgp = require('pg-promise')({
  promiseLib: Promise
});
pgp.pg = pg;

const accountingConn = pgp({
  user: 'derole',
  host: 'localhost',
  database: 'de',
  password: '0yI53&1mTqEDM3Y',
  port: 5432,
});

module.exports = accountingConn;