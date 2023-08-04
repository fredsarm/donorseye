const accountingConn = require ('../../connections/accountingConn');
 
const masterDetailQuery = async function (req, res, schemaName,tableName)  {
  
    try {
  
      let { pWh , language } = req.query;
  
      /* In the data dictionary table, there are records representing columns from all the tables in the database, including the columns of the data dictionary table itself where we record translations for various languages. Each language has its own column.
      In the list of records from the data dictionary table, there are these columns that are flagged as columns that enter the language list when marked as 'true' in the on_allowed_language_list column.
      To get a list of allowed languages, we perform a select on the column ids (slicing and extracting the column names contained in an id that includes the schema name, table name, and column name, separated by dots), filtered by the field on_allowed_language_list = true.
      This list is used to validate the language inserted in the main query of this module and to prevent SQL injection.*/
      let availableLanguages = await accountingConn.any('\
      SELECT REVERSE(split_part(REVERSE(col_id), \'.\', 1)) AS language_list \
      FROM syslogic.bas_data_dic \
      WHERE on_allowed_language_list = true');
  
      // convert availableLanguages into an array of strings
      const allowedLanguages = availableLanguages.map(obj => obj.language_list);
  
      if (!language) {
        throw new Error('You have to define a language.');
      } else {
        if (!allowedLanguages.includes(language)){
          throw new Error('This language is not suported.');
        } 
      }
    
      const columnsAndLabels = await accountingConn.any('\
      SELECT col.col_name, dic.' + language + ' \
      FROM syslogic.bas_data_dic AS dic \
      JOIN syslogic.bas_all_columns AS col \
      ON dic.col_id = col.text_id \
      WHERE col.sch_name = $1 \
      AND col.tab_name = $2 \
      AND col.show_front_end = $3\
      ', [schemaName, tableName, true]);

      // Create the variable to be used for checking if the columns passed with as arguments with the URL is available
      const columns = columnsAndLabels.map(obj => obj.col_name);
      const allowedCompOps = ['=', '>', '<', '<>','<=','>=','ILIKE','NOT ILIKE'];
      const allowedLogOps = ['AND','OR','NOT'];

      // Begin building the main query
      let query = `SELECT ${columns} FROM ${schemaName}.${tableName}`;
  
      // Initialize array to store the values to be used on WHERE clauses
      let values = [];

      // Check if a WHERE clause was passed with the API URL.
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
    
      // Execute the query
      const data = await accountingConn.any(query,values);
      console.log(data);
  
      let transIDs = data.map(trans => trans.parent_id.toString());
      console.log(transIDs);
  
      // Converte o array para um Set para remover duplicatas
      transIDs = new Set(transIDs);
      console.log(transIDs);
  
      // Converte o Set de volta para um array
  
      transIDs = Array.from(transIDs);
      console.log(transIDs);
  
      const child = await accountingConn.any(`SELECT ${columns} FROM ${schemaName}.${tableName} WHERE parent_id IN (${transIDs})`);
      console.log(child);
  
      // Return the result and the dictionary for the table columns
      const result = {
          'data': data,
          'columnsAndLabels':columnsAndLabels,
          'child':child
        };
  
        console.log(result.data.parent_id);
        console.log(result.data.parent_id);
         console.log(result.columnsAndLabels);
  
        res.json(result);
      } catch (err) {
        res.status(400).json({ error: err.message });
      }
    };
  
    module.exports = masterDetailQuery;
