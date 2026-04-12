const mysql = require('mysql2');
require('dotenv').config();

// 创建数据库连接池
const pool = mysql.createPool({
  host: process.env.DB_HOST || '47.242.48.154',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_DATABASE || 'medgsp',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  connectTimeout: 10000
});

// 测试数据库连接
pool.getConnection((err, connection) => {
  if (err) {
    console.error('数据库连接失败:', err.message);
    console.log('请检查:');
    console.log('1. MySQL容器是否运行: docker ps | grep mysql-medgsp');
    console.log('2. 防火墙设置: 端口3306是否开放');
    console.log('3. 数据库密码是否正确');
  } else {
    console.log('✅ 数据库连接成功');
    connection.release();
  }
});

// 创建Promise版本的查询方法
const promisePool = pool.promise();

module.exports = {
  pool,
  promisePool
};