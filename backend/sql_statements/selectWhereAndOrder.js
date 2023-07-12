const express = require('express');
const router = express.Router();
const knex = require('../db_connections/accConnection.js');

module.exports = async function createSelectWhereAndOrder(req,res,tableName, allowCols) {
    const allowCompOps = ['=', '>', '<', '<>','<=','>=','ILIKE','NOT ILIKE'];
    const allowLogOps = ['AND','OR','NOT'];
    const allowDirs = ['ASC', 'DESC'];
    try {
        let { select, where, orderBy } = req.query;
        if (!Array.isArray(select)) {
            select = allowCols[0];
        }

        let query = knex.select(select).from(tableName);
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

        console.log(query.toString());
        const data = await query;
        res.json(data);
    } catch (error) {
        console.error('Error retrieving data:', error);
        res.status(500).send('Internal Server Error');
    }
}


// url example: http://localhost:3000/api/accEveEntries?select[]=entry_id&select[]=credit&select[]=entry_date&select[]=debit&where[0][column]=entry_id&where[0][operator]=%3E&where[0][value]=50&where[1][logic]=AND&where[1][column]=debit&where[1][operator]=%3C=&where[1][value]=1000&where[2][logic]=AND&where[2][column]=entry_date&where[2][operator]=%3E&where[2][value]=2023-01-01&orderBy[0][column]=entry_date&orderBy[0][direction]=desc
