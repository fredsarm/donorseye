// src/queries/mainQuery.js 
// This is a generic query module that query any table data and its respective columns names translations based on the data dictionary table (syslogic.bas_data_dic).
// Import connection to accounting database
const accountingConn = require ('../connections/accountingConn');

// Define mainQuery as an async function
module.exports = async function dictQuery(req,schemaName,tableName) {

  // Declare URL parameters
  let { pCols , pWh , pOb, language } = req.query;

  // Define allowed columns. Firstly, it querys the column names available for the table 
  // that is being passed as argument using a join that also selects its respective 
  // translation based on the language variale that is passed with the route URL 
  const allowedColumnsResult = await accountingConn.any('SELECT col.col_name, dic.' + language + ' FROM syslogic.bas_data_dic AS dic JOIN syslogic.bas_all_columns AS col ON dic.col_id = col.text_id WHERE col.sch_name = $1 AND col.tab_name = $2 AND col.show_front_end = $3', [schemaName, tableName, true]);
  // Create the variable to be used for checking if the columns passed as arguments with the URL is available
  const allowedColumns = allowedColumnsResult.map(obj => obj.col_name);
  // Define all allowed comparison operators, logical operators, and ordering directions
  const allowedCompOps = ['=', '>', '<', '<>','<=','>=','ILIKE','NOT ILIKE'];
  const allowedLogOps = ['AND','OR','NOT'];
  const allowedDirs = ['ASC', 'DESC'];
  // Retrieve query parameters from request
  let query;
  // Check if columns to fetch are defined
  if (!pCols) {
    throw new Error('You have to define what columns you want to fetch. If you did define some columns, verify if the name of the parameter is \'pCols\' or if the syntax is pCols=["columnName"]');
  } else {
    let pColsArr=pCols.split(',');
    // Check if all defined columns are allowed
    for (let col of pColsArr) {
      if (!allowedColumns.includes(col)) {
        throw new Error('Column doesn\'t exist!');
      }
    }
    
  }

  // Initialize array to store the values
  let values = [];
  // Start building the query
  query = `SELECT ${pCols} FROM ${schemaName}.${tableName}`;

  // Check if WHERE clause is defined
  if (pWh) {
    // Convert string back to object
    pWh = JSON.parse(decodeURIComponent(pWh));
    query += ' WHERE';

    // Process conditions in WHERE clause
    for (let i = 0; i < pWh.length; i++) {
      const condition = pWh[i];
      // Add wildcard character to value if comparison operator is ILIKE or NOT ILIKE
      if (condition.comparisonOperator==="ILIKE" || condition.comparisonOperator==="NOT ILIKE") {
        condition.value=`%${condition.value}%`;
        // console.log (condition.value);
      }
      
      // Process the first condition
      if (i === 0) {
        // Check if all required elements of the condition are valid
        if (!condition.col 
          || !condition.comparisonOperator 
          || !condition.value
          || !allowedColumns.includes(condition.col) 
          || !allowedCompOps.includes(condition.comparisonOperator)) {
          throw new Error('Error in the first condition. Check if some element of the clause such as column, comparison operator or the value is missing or invalid');
        } else {
          // Add the value to the array of values
          values.push(condition.value);
          // Add the condition to the query
          query += ` ${condition.col} ${condition.comparisonOperator} $${values.length}`; // Use the length of the values array for placeholders numbering
        }
        
      } else {
        // Add wildcard character to value if comparison operator is ILIKE or NOT ILIKE
        if (condition.comparisonOperator==="ILIKE" || condition.comparisonOperator==="NOT ILIKE") {
          condition.value=`%${condition.value}%`;
        }

        // Check if all required elements of the condition are valid
        if (!condition.logicOperator
          || !condition.col 
          || !condition.comparisonOperator 
          || !condition.value
          || !allowedColumns.includes(condition.col) 
          || !allowedCompOps.includes(condition.comparisonOperator) 
          || !allowedLogOps.includes(condition.logicOperator)) {
            throw new Error('Error in one condition. Check if some element of the clause such as logic operator, column, comparison operator or the value is missing or invalid');
        } else {
          // Add the value to the array of values
          values.push(condition.value);
          // Add the condition to the query
          query += ` ${condition.logicOperator} ${condition.col} ${condition.comparisonOperator} $${values.length}`; // Use the length of the values array for placeholders numbering
        }
      }
    }
  }

  // Check if ORDER BY clause is defined
  if (pOb) {
    // Convert string back to object
    pOb = JSON.parse(decodeURIComponent(pOb));
    query += ' ORDER BY';
    // Process ordering conditions
    for (let i = 0; i < pOb.length; i++) {
      const order = pOb[i];
      // Check if the column and direction are valid
      if (!allowedColumns.includes(order.col) || !allowedDirs.includes(order.direction)) {
        throw new Error('Invalid order by clause.');
      }
      // If it's not the first ORDER BY clause, add a comma
      if (i !== 0) {
        query += ',';
      }
      // Add the ORDER BY clause to the query
      query += ` ${order.col} ${order.direction}`;
    }
  }

  // Execute the query
  const data = await accountingConn.any(query,values);



  
  // Return the result and the dictionary for the table columns
  return {
    'data': data,
    'dictData':allowedColumnsResult
  };
};

/*
Rules:
All 4 parâmeters have to be passed with the URL. If you don't want to set a WHERE or ORDER BY clause, pass it anyway but with empty value, like this:
const pWh = '';
const pOb = '';
All operators have to be uppercase (AND, OR, NOT, ILIKE not and, or, not, ilike)
In case of ILIKE or NOT ILIKE parameter, do not include the % in the URL. This module will include it at the processing time. 
These are examples of the 4 parameters included in the front-end app:

    const pCols = 'entry_id,entry_date,memo,debit,credit';
    const pWh = encodeURIComponent(JSON.stringify([{"col":"entry_id","comparisonOperator":"<","value":"30000"},{"logicOperator":"AND","col":"memo","comparisonOperator":"ILIKE","value":"reembolso"}]));
    const pOb = encodeURIComponent(JSON.stringify([{"col":"entry_date","direction":"DESC"},{"col":"entry_id","direction":"DESC"}]));
    const language = 'en_us';
*/
