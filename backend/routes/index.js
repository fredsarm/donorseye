const express = require('express');
const router = express.Router();

// Import the routes
const accChartRoutes = require('./accounting/bas_acc_chart');
const accEntriesRoutes = require('./accounting/eve_entries');
const basEntitiesRoutes = require('./entities/bas_entities');
const permissionsRoutes = require('./auth/bas_permissions');
const rolesRoutes = require('./auth/bas_roles');
const tablePermissionsRoutes = require('./auth/bas_table_permissions');
const tablesRoutes = require('./auth/bas_tables');
const usersRoutes = require('./auth/bas_users');
const accessTokensRoutes = require('./auth/eve_access_tokens');
const auditLogRoutes = require('./auth/eve_audit_log');
const refreshTokensRoutes = require('./auth/eve_refresh_tokens');

// Use the routes
router.use('/accChart', accChartRoutes);
router.use('/accEntries', accEntriesRoutes);
router.use('/permissions', permissionsRoutes);
router.use('/roles', rolesRoutes);
router.use('/tablePermissions', tablePermissionsRoutes);
router.use('/tables', tablesRoutes);
router.use('/users', usersRoutes);
router.use('/accessTokens', accessTokensRoutes);
router.use('/auditLog', auditLogRoutes);
router.use('/refreshTokens', refreshTokensRoutes);
router.use('/basEntities', basEntitiesRoutes);

module.exports = router;
