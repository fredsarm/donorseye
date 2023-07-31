// src/pages/api/entries.js
const accountingConn = require ('../../connections/accountingConn');
const schemaName = 'accounting';
const tableName = 'vw_eve_entries';

export default async (req, res) => { // next.js will import it
  try {

    let { pCols , pWh , pOb, language } = req.query;

    /*  In the data dictionary table, there are records representing columns from all the tables in the database, including the columns of the data dictionary table itself where we record translations for various languages. Each language has its own column.
    In the list of records from the data dictionary table, there are these columns that are flagged as columns that enter the language list when marked as 'true' in the on_allowed_language_list column.
    To get a list of allowed languages, we perform a select on the column ids (slicing and extracting the column names contained in an id that includes the schema name, table name, and column name, separated by dots), filtered by the field on_allowed_language_list = true.
    This list is used to validate the language inserted in the main query of this module and to prevent SQL injection.*/
    let allowedLanguageListResult = await accountingConn.any('SELECT REVERSE(split_part(REVERSE(col_id), \'.\', 1)) AS language_list FROM syslogic.bas_data_dic WHERE on_allowed_language_list = true');
    // convert allowedLanguageListResult into an array of strings
    const allowedLanguageList = allowedLanguageListResult.map(obj => obj.language_list);
    if (!language) {
      throw new Error('You have to define a language.');
    } else {
      if (!allowedLanguageList.includes(language)){
        throw new Error('This language is not suported.');
      } 
    }
  
    const translatedColumns = await accountingConn.any('\
    SELECT col.col_name, dic.' + language + ' \
    FROM syslogic.bas_data_dic AS dic \
    JOIN syslogic.bas_all_columns AS col \
    ON dic.col_id = col.text_id \
    WHERE col.sch_name = $1 AND col.tab_name = $2 AND col.show_front_end = $3\
    ', [schemaName, tableName, true]);
    const allowedColumns = [
      'entry_id',     
      'entry_parent', 
      'acc_id',
      'entity_id',
      'entry_date',
      'occur_date',   
      'memo',
      'credit',       
      'debit',
      'balance',
      'user_id'      
    ]

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
  
    // Start building the query
    query = `SELECT ${pCols} FROM ${schemaName}.${tableName}`;

    // Initialize array to store the values to be used on WHERE clauses
    let values = [];
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
    let data = await accountingConn.any(query,values);
    // Iterate over data to convert required fields

    // Return the result and the dictionary for the table columns
    const result = {
        'data': data,
        'dictData':translatedColumns
      };
      res.json(result);
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  };

  /*
  Rules:
  All 4 parâmeters have to be passed with the URL. If you don't want to set a WHERE or ORDER BY clause, pass it anyway but with empty value, like this:
  const pWh = '';
  const pOb = '';
  All operators have to be uppercase (AND, OR, NOT, ILIKE not and, or, not, ilike)
  In case of ILIKE or NOT ILIKE parameter, do not include the % in the URL. This module will include it at the processing time. 
  These are examples of the 4 parameters that could be included in the front-end app:
  
      const pCols = 'entry_id,entry_date,memo,debit,credit';
      const pWh = encodeURIComponent(JSON.stringify([{"col":"entry_id","comparisonOperator":"<","value":"30000"},{"logicOperator":"AND","col":"memo","comparisonOperator":"ILIKE","value":"reembolso"}]));
      const pOb = encodeURIComponent(JSON.stringify([{"col":"entry_date","direction":"DESC"},{"col":"entry_id","direction":"DESC"}]));
      const language = 'en_us';
  */