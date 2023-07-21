// conns.js - aqui serão criadas várias configurações de conexões para usar em diferentes partes da app

const pgp = require('pg-promise')();

const db = pgp({
  user: 'derole',
  host: 'localhost',
  database: 'de',
  password: '0yI53&1mTqEDM3Y',
  port: 5432,
});

module.exports = {
  query: (text, params) => db.any(text, params),
}; 
