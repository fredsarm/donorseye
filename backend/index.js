const express = require('express');
const app = express();

// Import index routes
const routes = require('./routes/index');

// Use routes
app.use('/api', routes);

// Start the server
app.listen(3000, () => {
  console.log('Server started on port: 3000');
});
