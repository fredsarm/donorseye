const express = require('express');
const router = express.Router();

// Standard:
// accountingEveEntries
//     ^      ^    ^
//  schema  type table

// schema: data model schema () PostgreSQL
// type: eve (register events), bas (basic database), lnk (in between table for relationships many to many), sys (other app tables)
// table: the name of the table

// Import the routes
const accBasChart = require('./accounting/bas_acc_chart');
const accEveEntries = require('./accounting/eve_entries');
const entBasEntities = require('./entities/bas_entities');
const authBasPerms = require('./auth/bas_permissions');
const authBasRoles = require('./auth/bas_roles');
const authBasTabPerms = require('./auth/bas_table_permissions');
const authBasTabs = require('./auth/bas_tables');
const authBasUsers = require('./auth/bas_users');
const authEveTokens = require('./auth/eve_access_tokens');
const authEveAudit = require('./auth/eve_audit_log');
const authEveRefresh = require('./auth/eve_refresh_tokens');

// Use the routes
router.use('/accBasChart', accBasChart);
router.use('/accEveEntries', accEveEntries);
router.use('/entBasEntities', entBasEntities);
router.use('/authBasPerms', authBasPerms);
router.use('/authBasRoles', authBasRoles);
router.use('/authBasTabPerms', authBasTabPerms);
router.use('/authBasTabs', authBasTabs);
router.use('/authBasUsers', authBasUsers);
router.use('/authEveTokens', authEveTokens);
router.use('/authEveAudit', authEveAudit);
router.use('/authEveRefresh', authEveRefresh);

module.exports = router;
