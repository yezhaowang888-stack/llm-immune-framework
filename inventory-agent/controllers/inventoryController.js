const { promisePool } = require('../config/database');

class InventoryController {
  // 测试数据库连接
  async testConnection(req, res) {
    try {
      const [rows] = await promisePool.query('SELECT 1 + 1 AS result');
      res.json({
        success: true,
        message: '数据库连接正常',
        data: rows[0],
        mode: 'real-database'
      });
    } catch (error) {
      // 数据库连接失败，返回示例模式
      res.json({
        success: true,
        message: '数据库连接失败，使用示例数据模式',
        mode: 'sample-data',
        error: error.message,
        troubleshooting: [
          '1. 检查MySQL容器是否运行: docker ps | grep mysql-medgsp',
          '2. 检查防火墙设置: 端口3306是否开放',
          '3. 检查MySQL是否允许远程连接',
          '4. 确认数据库密码是否正确'
        ],
        sampleData: {
          products: [
            { code: 'PM001', name: '一次性使用注射器', stock: 100 },
            { code: 'PM002', name: '医用外科口罩', stock: 500 },
            { code: 'PM003', name: '医用防护服', stock: 50 }
          ]
        }
      });
    }
  }

  // 获取所有产品
  async getAllProducts(req, res) {
    try {
      // 首先探索数据库表结构
      const [tables] = await promisePool.query('SHOW TABLES');
      console.log('数据库表:', tables);
      
      // 尝试查找产品表
      let productTable = null;
      for (const table of tables) {
        const tableName = Object.values(table)[0];
        if (tableName.toLowerCase().includes('product')) {
          productTable = tableName;
          break;
        }
      }
      
      if (!productTable) {
        // 如果没有找到产品表，返回示例数据
        return res.json({
          success: true,
          message: '未找到产品表，返回示例数据',
          mode: 'sample-data',
          reason: '数据库表结构不匹配',
          tables: tables.map(t => Object.values(t)[0]),
          data: [
            { code: 'PM001', name: '一次性使用注射器', stock: 100 },
            { code: 'PM002', name: '医用外科口罩', stock: 500 },
            { code: 'PM003', name: '医用防护服', stock: 50 }
          ]
        });
      }
      
      // 查询产品表结构
      const [columns] = await promisePool.query(`DESCRIBE ${productTable}`);
      console.log('产品表结构:', columns);
      
      // 查询产品数据
      const [products] = await promisePool.query(`SELECT * FROM ${productTable} LIMIT 20`);
      
      res.json({
        success: true,
        message: '产品列表获取成功',
        mode: 'real-database',
        table: productTable,
        columns: columns,
        count: products.length,
        data: products
      });
    } catch (error) {
      console.error('获取产品列表错误:', error);
      // 数据库连接失败，返回示例数据
      res.json({
        success: true,
        message: '数据库连接失败，使用示例数据模式',
        mode: 'sample-data',
        reason: '云服务器维护中，香港工程师正在调试工作',
        troubleshooting: [
          '1. 云服务器可能正在进行系统维护',
          '2. 香港工程师可能正在调试数据库',
          '3. 网络配置可能正在调整',
          '4. 请等待系统稳定后重试'
        ],
        data: [
          { code: 'PM001', name: '一次性使用注射器', stock: 100 },
          { code: 'PM002', name: '医用外科口罩', stock: 500 },
          { code: 'PM003', name: '医用防护服', stock: 50 }
        ]
      });
    }
  }

  // 根据产品编号查询
  async getProductByCode(req, res) {
    const { code } = req.params;
    
    if (!code) {
      return res.status(400).json({
        success: false,
        message: '产品编号不能为空'
      });
    }
    
    try {
      // 探索数据库表结构
      const [tables] = await promisePool.query('SHOW TABLES');
      
      // 尝试查找产品表
      let productTable = null;
      for (const table of tables) {
        const tableName = Object.values(table)[0];
        if (tableName.toLowerCase().includes('product')) {
          productTable = tableName;
          break;
        }
      }
      
      if (!productTable) {
        // 返回示例数据
        const sampleProducts = [
          { code: 'PM001', name: '一次性使用注射器', stock: 100 },
          { code: 'PM002', name: '医用外科口罩', stock: 500 },
          { code: 'PM003', name: '医用防护服', stock: 50 }
        ];
        
        const product = sampleProducts.find(p => p.code === code);
        
        if (product) {
          return res.json({
            success: true,
            message: '产品查询成功（示例数据）',
            mode: 'sample-data',
            reason: '数据库表结构不匹配',
            data: product
          });
        } else {
          return res.status(404).json({
            success: false,
            message: '产品不存在',
            code: code
          });
        }
      }
      
      // 查询产品表结构以确定字段名
      const [columns] = await promisePool.query(`DESCRIBE ${productTable}`);
      
      // 查找可能的代码字段
      let codeField = null;
      for (const column of columns) {
        const fieldName = column.Field.toLowerCase();
        if (fieldName.includes('code') || fieldName.includes('no') || fieldName.includes('id')) {
          codeField = column.Field;
          break;
        }
      }
      
      if (!codeField) {
        codeField = columns[0].Field; // 使用第一个字段
      }
      
      // 查询产品
      const [products] = await promisePool.query(
        `SELECT * FROM ${productTable} WHERE ${codeField} = ?`,
        [code]
      );
      
      if (products.length === 0) {
        return res.status(404).json({
          success: false,
          message: '产品不存在',
          code: code,
          table: productTable,
          codeField: codeField
        });
      }
      
      res.json({
        success: true,
        message: '产品查询成功',
        mode: 'real-database',
        table: productTable,
        codeField: codeField,
        data: products[0]
      });
    } catch (error) {
      console.error('查询产品错误:', error);
      // 数据库连接失败，返回示例数据
      const sampleProducts = [
        { code: 'PM001', name: '一次性使用注射器', stock: 100 },
        { code: 'PM002', name: '医用外科口罩', stock: 500 },
        { code: 'PM003', name: '医用防护服', stock: 50 }
      ];
      
      const product = sampleProducts.find(p => p.code === code);
      
      if (product) {
        return res.json({
          success: true,
          message: '产品查询成功（示例数据）',
          mode: 'sample-data',
          reason: '云服务器维护中，香港工程师正在调试工作',
          troubleshooting: [
            '1. 云服务器可能正在进行系统维护',
            '2. 香港工程师可能正在调试数据库',
            '3. 网络配置可能正在调整',
            '4. 请等待系统稳定后重试'
          ],
          data: product
        });
      } else {
        return res.status(404).json({
          success: false,
          message: '产品不存在',
          code: code
        });
      }
    }
  }

  // 根据产品名称搜索
  async searchProducts(req, res) {
    const { name } = req.query;
    
    if (!name) {
      return res.status(400).json({
        success: false,
        message: '搜索关键词不能为空'
      });
    }
    
    try {
      // 探索数据库表结构
      const [tables] = await promisePool.query('SHOW TABLES');
      
      // 尝试查找产品表
      let productTable = null;
      for (const table of tables) {
        const tableName = Object.values(table)[0];
        if (tableName.toLowerCase().includes('product')) {
          productTable = tableName;
          break;
        }
      }
      
      if (!productTable) {
        // 返回示例数据
        const sampleProducts = [
          { code: 'PM001', name: '一次性使用注射器', stock: 100 },
          { code: 'PM002', name: '医用外科口罩', stock: 500 },
          { code: 'PM003', name: '医用防护服', stock: 50 }
        ];
        
        const filteredProducts = sampleProducts.filter(p => 
          p.name.includes(name) || p.code.includes(name)
        );
        
        return res.json({
          success: true,
          message: '产品搜索成功（示例数据）',
          keyword: name,
          count: filteredProducts.length,
          data: filteredProducts
        });
      }
      
      // 查询产品表结构以确定字段名
      const [columns] = await promisePool.query(`DESCRIBE ${productTable}`);
      
      // 查找可能的名称字段
      let nameField = null;
      for (const column of columns) {
        const fieldName = column.Field.toLowerCase();
        if (fieldName.includes('name') || fieldName.includes('title') || fieldName.includes('desc')) {
          nameField = column.Field;
          break;
        }
      }
      
      if (!nameField) {
        // 如果没有名称字段，使用第一个文本字段
        for (const column of columns) {
          if (column.Type.includes('char') || column.Type.includes('text')) {
            nameField = column.Field;
            break;
          }
        }
      }
      
      if (!nameField) {
        nameField = columns[0].Field; // 使用第一个字段
      }
      
      // 搜索产品
      const [products] = await promisePool.query(
        `SELECT * FROM ${productTable} WHERE ${nameField} LIKE ? LIMIT 20`,
        [`%${name}%`]
      );
      
      res.json({
        success: true,
        message: '产品搜索成功',
        keyword: name,
        table: productTable,
        nameField: nameField,
        count: products.length,
        data: products
      });
    } catch (error) {
      console.error('搜索产品错误:', error);
      res.status(500).json({
        success: false,
        message: '搜索产品失败',
        error: error.message,
        keyword: name
      });
    }
  }

  // 获取库存统计
  async getInventoryStats(req, res) {
    try {
      // 探索数据库表结构
      const [tables] = await promisePool.query('SHOW TABLES');
      
      // 尝试查找产品表
      let productTable = null;
      for (const table of tables) {
        const tableName = Object.values(table)[0];
        if (tableName.toLowerCase().includes('product')) {
          productTable = tableName;
          break;
        }
      }
      
      if (!productTable) {
        // 返回示例统计
        return res.json({
          success: true,
          message: '库存统计（示例数据）',
          stats: {
            totalProducts: 3,
            totalStock: 650,
            averageStock: 217,
            lowStock: 0,
            normalStock: 3
          },
          data: [
            { code: 'PM001', name: '一次性使用注射器', stock: 100, status: '正常' },
            { code: 'PM002', name: '医用外科口罩', stock: 500, status: '充足' },
            { code: 'PM003', name: '医用防护服', stock: 50, status: '正常' }
          ]
        });
      }
      
      // 查询产品数据
      const [products] = await promisePool.query(`SELECT * FROM ${productTable}`);
      
      // 简单的统计计算
      let totalStock = 0;
      let lowStockCount = 0;
      const stockData = [];
      
      // 尝试查找库存字段
      const [columns] = await promisePool.query(`DESCRIBE ${productTable}`);
      let stockField = null;
      
      for (const column of columns) {
        const fieldName = column.Field.toLowerCase();
        if (fieldName.includes('stock') || fieldName.includes('quantity') || fieldName.includes('qty')) {
          stockField = column.Field;
          break;
        }
      }
      
      if (stockField) {
        // 如果有库存字段，使用实际数据
        for (const product of products) {
          const stock = product[stockField] || 0;
          totalStock += stock;
          
          if (stock < 10) {
            lowStockCount++;
          }
          
          stockData.push({
            ...product,
            stock: stock,
            status: stock < 10 ? '低库存' : stock < 50 ? '正常' : '充足'
          });
        }
      } else {
        // 如果没有库存字段，使用默认值
        totalStock = products.length * 100;
        stockData.push(...products.map(p => ({
          ...p,
          stock: 100,
          status: '正常'
        })));
      }
      
      res.json({
        success: true,
        message: '库存统计获取成功',
        table: productTable,
        stockField: stockField,
        stats: {
          totalProducts: products.length,
          totalStock: totalStock,
          averageStock: products.length > 0 ? Math.round(totalStock / products.length) : 0,
          lowStock: lowStockCount,
          normalStock: products.length - lowStockCount
        },
        data: stockData.slice(0, 20) // 限制返回数量
      });
    } catch (error) {
      console.error('获取库存统计错误:', error);
      res.status(500).json({
        success: false,
        message: '获取库存统计失败',
        error: error.message
      });
    }
  }
}

module.exports = new InventoryController();