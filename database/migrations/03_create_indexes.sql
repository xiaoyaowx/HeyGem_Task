-- 使用数据库
USE heygem_task_db;

-- 为数字人模型表添加索引
CREATE INDEX idx_digital_humans_status ON digital_humans(status);
CREATE INDEX idx_digital_humans_api_key ON digital_humans(api_key);

-- 为API密钥表添加索引
CREATE INDEX idx_api_keys_is_active ON api_keys(is_active);

-- 为任务表添加索引
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_digital_human_id ON tasks(digital_human_id);
CREATE INDEX idx_tasks_api_key ON tasks(api_key);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);

-- 为任务日志表添加索引
CREATE INDEX idx_task_logs_task_id ON task_logs(task_id);
CREATE INDEX idx_task_logs_created_at ON task_logs(created_at);
