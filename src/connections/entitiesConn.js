const pgp = require('pg-promise')();

const entitiesConn = pgp({
    user: 'entitiesrole',
    host: 'localhost',
    database: 'de',
    password: '0yI53&1mTqEDM3Y',
    port: 5432,
  });
  
  module.exports = entitiesConn;