const express = require('express');
const router = express.Router();
const inventoryController = require('../controllers/inventoryController');

// 获取所有产品
router.get('/products', inventoryController.getAllProducts);

// 根据产品编号查询
router.get('/product/:code', inventoryController.getProductByCode);

// 根据产品名称搜索
router.get('/search', inventoryController.searchProducts);

// 获取库存统计
router.get('/stats', inventoryController.getInventoryStats);

// 测试数据库连接
router.get('/test-connection', inventoryController.testConnection);

module.exports = router;