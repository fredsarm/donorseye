const pgp = require('pg-promise')();

const accountingConnection = {
  host: 'localhost',
  port: 5432,
  database: 'de',
  user: 'derole',
  password: '0yI53&1mTqEDM3Y'
};

const db = pgp(accountingConnection);

module.exports = db;
