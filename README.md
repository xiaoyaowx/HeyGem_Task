# 数字人视频处理任务系统开发规划文档

## 1. 系统概述

本系统旨在提供统一的API接口，用于管理数字人合成任务。系统将支持任务提交、状态查询、结果获取等功能，并通过MySQL数据库实现任务信息的持久化存储。前端界面将实时展示任务执行状态，为用户提供直观的任务监控体验。

## 2. 技术栈选择

### 前端
- **框架**：Next.js 15
- **状态管理**：React Context API（轻量级）
- **UI组件库**：TailwindCSS + HeadlessUI（轻量级组合）
- **数据可视化**：Chart.js（轻量级）
- **实时通信**：轮询 / EventSource（简单实现）

### 后端
- **框架**：Next.js 15 (API Routes)
- **数据库**：MySQL（直接SQL操作）
- **任务队列**：简单的内存队列 + 定时任务
- **认证**：简单API密钥验证

### 部署
- **容器化**：Docker
- **服务器**：Linux (推荐Ubuntu LTS)

## 3. 数据库设计

### 数字人模型表 (digital_humans)
```sql
CREATE TABLE digital_humans (
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
```

### 任务表 (tasks)
```sql
CREATE TABLE tasks (
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
```

### API密钥表 (api_keys)
```sql
CREATE TABLE api_keys (
    id VARCHAR(36) PRIMARY KEY,
    api_key VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP NULL
);
```

### 任务日志表 (task_logs)
```sql
CREATE TABLE task_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id VARCHAR(36) NOT NULL,
    status ENUM('pending', 'processing', 'completed', 'failed') NOT NULL,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);
```

## 4. API接口设计

### API密钥验证
- 所有API请求需要在Header中包含 `X-API-KEY` 进行验证

### 数字人模型管理
- `POST /api/digital-humans` - 创建新的数字人模型
- `GET /api/digital-humans` - 获取数字人模型列表
- `GET /api/digital-humans/:id` - 获取特定数字人模型详情
- `PUT /api/digital-humans/:id` - 更新数字人模型信息
- `DELETE /api/digital-humans/:id` - 删除数字人模型

### 任务管理
- `POST /api/tasks` - 创建新任务（必须指定数字人模型）
- `GET /api/tasks` - 获取任务列表（支持分页、筛选）
- `GET /api/tasks/:id` - 获取特定任务详情
- `GET /api/tasks/:id/status` - 获取特定任务状态
- `DELETE /api/tasks/:id` - 删除特定任务
- `GET /api/tasks/stats` - 获取任务统计信息

### 文件管理
- `POST /api/upload` - 上传音频/视频文件
- `GET /api/videos/:id` - 获取生成的视频

## 5. 前端页面设计

### 主要页面
1. **任务仪表盘**
   - 展示任务统计信息
   - 显示最近任务列表
   - 任务状态统计图表

2. **数字人模型管理页面**
   - 数字人模型列表展示
   - 创建新数字人模型功能
   - 数字人缩略图展示

3. **任务列表页面**
   - 支持简单筛选和排序
   - 显示任务基本信息和状态

4. **任务详情页面**
   - 显示任务详细信息
   - 实时进度条
   - 任务日志
   - 视频预览（任务完成后）

5. **新建任务页面**
   - 选择数字人模型（必选）
   - 音频文件上传组件
   - 任务参数配置表单

### 组件设计
1. **任务卡片组件** - 简洁展示单个任务的基本信息
2. **进度条组件** - 展示任务执行进度
3. **状态标签组件** - 以不同颜色展示任务状态
4. **文件上传组件** - 处理音频/视频上传
5. **视频播放器组件** - 基础HTML5播放器
6. **简单筛选组件** - 基础任务筛选功能

## 6. 任务处理流程

1. **任务提交**
   - 用户上传音频和视频文件
   - 系统生成唯一任务ID
   - 保存任务信息到数据库
   - 将任务添加到处理队列

2. **任务执行**
   - 工作进程从队列获取任务
   - 更新任务状态为"processing"
   - 调用HeyGem核心处理服务
   - 定期更新任务进度
   - 记录处理日志

3. **任务完成**
   - 更新任务状态为"completed"或"failed"
   - 存储结果视频URL（如果成功）
   - 记录错误信息（如果失败）
   - 通知前端任务完成

4. **结果获取**
   - 用户请求查看任务结果
   - 系统返回视频URL或错误信息
   - 提供视频下载/播放功能

## 7. 与HeyGem集成

### 集成方案
**直接调用方式**
- 创建HeyGem服务包装类
- 通过命令行调用处理服务
- 监控处理进程和输出

```javascript
// 示例代码：服务包装类
class HeyGemService {
  async processVideo(taskId, audioPath, options = {}) {
    try {
      // 创建数据库连接
      const connection = mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME
      });
      
      // 更新任务状态
      await connection.query(
        'UPDATE tasks SET status = ?, progress = ? WHERE id = ?',
        ['processing', 0, taskId]
      );
      
      // 获取任务信息
      const [taskRows] = await connection.query(
        'SELECT * FROM tasks WHERE id = ?',
        [taskId]
      );
      
      if (taskRows.length === 0) {
        throw new Error('任务不存在');
      }
      
      const task = taskRows[0];
      
      // 获取数字人模型信息
      const [digitalHumanRows] = await connection.query(
        'SELECT * FROM digital_humans WHERE id = ?',
        [task.digital_human_id]
      );
      
      if (digitalHumanRows.length === 0) {
        throw new Error('数字人模型不存在');
      }
      
      const videoPath = digitalHumanRows[0].video_path;
      
      // 执行处理命令
      const command = `python /path/to/run.py --audio_path ${audioPath} --video_path ${videoPath}`;
      
      // 执行命令并获取结果
      const { stdout, stderr } = await execPromise(command);
      
      // 获取结果路径（假设命令会输出结果路径）
      const resultPath = stdout.trim();
      
      // 更新任务状态为完成
      await connection.query(
        'UPDATE tasks SET status = ?, video_url = ?, completed_at = ? WHERE id = ?',
        ['completed', resultPath, new Date(), taskId]
      );
      
      connection.end();
      return resultPath;
    } catch (error) {
      const connection = mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME
      });
      
      // 处理错误
      await connection.query(
        'UPDATE tasks SET status = ?, error_message = ? WHERE id = ?',
        ['failed', error.message, taskId]
      );
      
      connection.end();
      throw error;
    }
  }
  
  // 新增创建数字人模型方法
  async createDigitalHuman(name, videoPath, description = '', apiKey, params = {}) {
    const connection = mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME
    });
    
    try {
      const id = uuidv4();
      // 创建缩略图
      const thumbnailUrl = await this.generateThumbnail(videoPath);
      
      await connection.query(
        'INSERT INTO digital_humans (id, name, description, video_path, thumbnail_url, api_key, params) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [id, name, description, videoPath, thumbnailUrl, apiKey, JSON.stringify(params)]
      );
      
      connection.end();
      return id;
    } catch (error) {
      connection.end();
      throw error;
    }
  }
  
  // 生成缩略图的辅助方法
  async generateThumbnail(videoPath) {
    // 使用ffmpeg从视频生成缩略图
    const outputPath = videoPath.replace(/\.[^/.]+$/, '') + '_thumbnail.jpg';
    const command = `ffmpeg -i ${videoPath} -ss 00:00:02 -frames:v 1 ${outputPath}`;
    
    await execPromise(command);
    return outputPath;
  }
}
```

## 8. 实时状态更新机制

### 方案选择
**轮询方式**
- 前端定期请求任务状态（如每5秒）
- 简单实现，适合小规模系统
- 无需额外服务器资源

```javascript
// 前端轮询示例
function TaskStatusPoller({ taskId }) {
  const [task, setTask] = useState(null);
  
  useEffect(() => {
    const checkStatus = async () => {
      try {
        const response = await fetch(`/api/tasks/${taskId}/status`);
        const data = await response.json();
        setTask(data);
        
        // 如果任务仍在进行中，继续轮询
        if (data.status === 'pending' || data.status === 'processing') {
          setTimeout(checkStatus, 5000);
        }
      } catch (error) {
        console.error('获取任务状态失败:', error);
      }
    };
    
    checkStatus();
    
    return () => clearTimeout(checkStatus);
  }, [taskId]);
  
  return (
    <div>
      <StatusBadge status={task?.status} />
      {task?.status === 'processing' && <ProgressBar value={task.progress} />}
    </div>
  );
}

## 9. 开发计划

### 阶段一：基础架构搭建（1周）
1. 项目初始化和配置
2. 数据库表设计和创建
3. API密钥验证机制实现
4. API基础架构

### 阶段二：核心功能开发（2周）
1. 任务提交和管理API
2. 文件上传和处理
3. HeyGem服务集成
4. 任务状态管理

### 阶段三：前端开发（1周）
1. 页面布局和路由设计
2. 组件开发
3. 轮询状态更新实现

### 阶段四：测试和优化（1周）
1. 基础功能测试
2. 性能优化
3. 安全性检查

### 阶段五：部署（3天）
1. Docker容器化
2. 部署文档编写
3. 上线准备

## 10. 扩展考虑

1. **简单任务优先级**：基础的优先级排序
2. **API请求限制**：限制单个API密钥的请求频率
3. **定时清理**：简单的脚本定期清理过期任务和文件

## 11. 技术挑战及解决方案

1. **文件上传处理**
   - 使用基础的表单上传
   - 设置合理的文件大小限制
   - 在上传前进行基本验证

2. **系统稳定性**
   - 使用进程管理工具（如PM2）确保服务稳定运行
   - 实现简单的错误处理和日志记录

3. **任务管理**
   - 使用简单的内存队列管理任务
   - 限制最大并发任务数

4. **安全性**
   - 使用简单有效的API密钥验证
   - 对上传文件进行类型和大小验证
   - 实现基本的请求频率限制

此规划文档提供了系统开发的基本框架和指导方针，采用轻量级技术栈和简化的架构，适合快速实现并满足基本需求。
