// src/connections/accountingConn.js 

const pgp = require('pg-promise')();

const accountingConn = pgp({
  user: 'derole',
  host: 'localhost',
  database: 'de',
  password: '0yI53&1mTqEDM3Y',
  port: 5432,
});

module.exports = accountingConn;
