/*
    express: framework.
    express.Router(): express' object.
    router.get('/'...): a method of the router

    */


const express = require('express');
const router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {

//  res.render('index', { title: 'Express' });
  res.send('Olá Mundo!! Aqui é o Fred criando o Donor\'s Eye!'); // Enviando uma resposta de texto simples

});

module.exports = router;
