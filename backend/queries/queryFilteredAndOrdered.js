const express = require('express');
const router = express.Router();
const knex = require('knex')({
  client: 'pg',
  connection: process.env.PG_CONNECTION_STRING
});

module.exports = async function queryFilteredAndOrdered(req,res,schemaName,tableName) {
    const queryCols = await knex.select('col_name')
                                  .from('syslogic.bas_all_columns')
                                  .where({
                                      'sch_name': schemaName,
                                      'tab_name': tableName,
                                      'show_front_end': true
                                  });

    const allowCols = queryCols.map(col => col.col_name); // extract column names to a simple array
    const allowCompOps = ['=', '>', '<', '<>','<=','>=','ILIKE','NOT ILIKE']; // Allowed comparison operators
    const allowLogOps = ['AND','OR','NOT']; // Allowed logic operators
    const allowDirs = ['ASC', 'DESC']; // Allowed directions for ORDER BY clause
    try {
        let { select, where, orderBy } = req.query;
        if (!Array.isArray(select)) {
            select = allowCols[0];
        }

        let query = knex.select(select).from(schemaName + '.' + tableName);
        if (Array.isArray(where)) {
            let errors = [];
            where.forEach((condition, index) => {
                const { column, operator, value, logic } = condition;
                // Validate column, operator, and value
                if (!allowCols.includes(column) || !allowCompOps.includes(operator) || !value) {
                    errors.push(`Invalid WHERE clause parameters for column: ${column}, Comparison Operator: ${operator}, Value: ${value}.`);
                } else {
                    if (index === 0) {
                        query = query.where(column, operator, value);
                    } else {
                        // Validate logic operator
                        if (!allowLogOps.includes(logic.toUpperCase())) {
                            errors.push(`Invalid logic operator: ${logic}`);
                        } else {
                            if (logic.toLowerCase() === 'and') {
                                query = query.andWhere(column, operator, value);
                            } else if (logic.toLowerCase() === 'or') {
                                query = query.orWhere(column, operator, value);
                            } else if (logic.toLowerCase() === 'not') {
                                query = query.whereNot(column, operator, value);
                            }
                        }
                    }
                }
            });

            if (errors.length > 0) {
                return res.status(400).json({ errors });
            }
        }

        if (Array.isArray(orderBy)) {
            orderBy.forEach(order => {
                const { column, direction } = order;
                query = query.orderBy(column, direction);
            });
        }

        // const data = await query;
        // res.json(data);

        console.log(query.toString());
        const data = await query;
        const translatedData = await translateColumnNames(data, schemaName, tableName, 'pt_br'); // usar uma variável no lugar deste hardcode en_us
        res.json(translatedData);

    } catch (error) {
        console.error('Error retrieving data:', error);
        res.status(500).send('Internal Server Error');
    }
}

// Aplica os nomes do dicionário às colunas de sistema
async function translateColumnNames(data, schemaName, tableName, language) {
    // Fetch column translations from the database
    const queryTranslatedCols = await knex.select('col_id', language)
                                          .from('syslogic.bas_data_dic')
                                          .whereIn('col_id', Object.keys(data[0]).map(col => `${schemaName}.${tableName}.${col}`));

    // Map column ids to their translations
    const translatedCols = {};
    queryTranslatedCols.forEach(col => {
        const colName = col.col_id.split('.').pop(); // Extract column name from 'schema.table.column'
        translatedCols[colName] = col[language];
    });

    // Apply column name translations to the data
    const dataWithTranslatedCols = data.map(row => {
        const translatedRow = {};
        for (const col in row) {
            if (translatedCols[col]) {
                translatedRow[translatedCols[col]] = row[col];
            } else {
                translatedRow[col] = row[col];
            }
        }
        return translatedRow;
    });

    return dataWithTranslatedCols;
}


// url example: http://localhost:3000/api/accEveEntries?select[]=entry_id&select[]=credit&select[]=entry_date&select[]=debit&where[0][column]=entry_id&where[0][operator]=%3E&where[0][value]=50&where[1][logic]=AND&where[1][column]=debit&where[1][operator]=%3C=&where[1][value]=1000&where[2][logic]=AND&where[2][column]=entry_date&where[2][operator]=%3E&where[2][value]=2023-01-01&orderBy[0][column]=entry_date&orderBy[0][direction]=desc
