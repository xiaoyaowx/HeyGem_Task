-- 使用数据库
USE heygem_task_db;

-- 创建数字人模型表 (digital_humans)
CREATE TABLE IF NOT EXISTS digital_humans (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    video_path VARCHAR(512) NOT NULL,
    thumbnail_url VARCHAR(512),
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    api_key VARCHAR(64) NOT NULL,
    params JSON
);

-- 创建API密钥表 (api_keys)
CREATE TABLE IF NOT EXISTS api_keys (
    id VARCHAR(36) PRIMARY KEY,
    api_key VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP NULL
);

-- 创建任务表 (tasks)
CREATE TABLE IF NOT EXISTS tasks (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status ENUM('pending', 'processing', 'completed', 'failed') NOT NULL DEFAULT 'pending',
    progress INT DEFAULT 0,
    video_url VARCHAR(512),
    audio_path VARCHAR(512) NOT NULL,
    digital_human_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    error_message TEXT,
    api_key VARCHAR(64) NOT NULL,
    priority INT DEFAULT 0,
    params JSON,
    FOREIGN KEY (digital_human_id) REFERENCES digital_humans(id)
);

-- 创建任务日志表 (task_logs)
CREATE TABLE IF NOT EXISTS task_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id VARCHAR(36) NOT NULL,
    status ENUM('pending', 'processing', 'completed', 'failed') NOT NULL,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);
