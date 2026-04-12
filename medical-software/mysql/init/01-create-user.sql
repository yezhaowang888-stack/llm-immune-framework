-- 创建同步专用用户
CREATE USER IF NOT EXISTS 'sync_user'@'%' IDENTIFIED BY 'sync_password_123';
GRANT SELECT, INSERT, UPDATE, DELETE ON medgsp.* TO 'sync_user'@'%';
FLUSH PRIVILEGES;