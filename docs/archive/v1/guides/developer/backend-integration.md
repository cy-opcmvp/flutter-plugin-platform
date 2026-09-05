# 后端服务器集成指南

## 概述

插件平台支持与后端服务器集成，提供以下功能：
- 用户认证和授权
- 插件云同步
- 远程插件分发
- 多设备数据同步
- 插件商店功能

## 后端API设计

### 1. 认证API

```typescript
// 用户注册
POST /api/auth/register
{
  "username": "string",
  "email": "string", 
  "password": "string"
}

// 用户登录
POST /api/auth/login
{
  "email": "string",
  "password": "string"
}

// 刷新Token
POST /api/auth/refresh
{
  "refreshToken": "string"
}
```

### 2. 插件管理API

```typescript
// 获取用户插件列表
GET /api/plugins/user
Headers: Authorization: Bearer <token>

// 安装插件
POST /api/plugins/install
{
  "pluginId": "string",
  "version": "string"
}

// 卸载插件
DELETE /api/plugins/{pluginId}

// 获取插件商店列表
GET /api/plugins/store?category=<category>&search=<query>

// 上传插件
POST /api/plugins/upload
Content-Type: multipart/form-data
```

### 3. 数据同步API

```typescript
// 同步插件数据
POST /api/sync/plugin-data
{
  "pluginId": "string",
  "data": "object",
  "timestamp": "string"
}

// 获取插件数据
GET /api/sync/plugin-data/{pluginId}

// 解决同步冲突
POST /api/sync/resolve-conflict
{
  "pluginId": "string",
  "conflictId": "string",
  "resolution": "local" | "remote" | "merge"
}
```

## Flutter客户端集成

### 1. 配置网络管理器

更新 `lib/core/services/network_manager.dart`:

```dart
class NetworkManager implements INetworkManager {
  static const String _baseUrl = 'https://your-api-server.com/api';
  String? _authToken;
  
  // 认证相关
  Future<AuthResult> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['accessToken'];
      return AuthResult.success(data);
    } else {
      return AuthResult.failure(response.body);
    }
  }
  
  // 插件相关
  Future<List<PluginDescriptor>> getStorePlugins() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/plugins/store'),
      headers: _getAuthHeaders(),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PluginDescriptor.fromJson(json)).toList();
    } else {
      throw NetworkException('Failed to fetch store plugins');
    }
  }
  
  Future<void> installPlugin(String pluginId, String version) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/plugins/install'),
      headers: _getAuthHeaders(),
      body: jsonEncode({
        'pluginId': pluginId,
        'version': version,
      }),
    );
    
    if (response.statusCode != 200) {
      throw NetworkException('Failed to install plugin');
    }
  }
  
  // 数据同步
  Future<void> syncPluginData(String pluginId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/plugin-data'),
      headers: _getAuthHeaders(),
      body: jsonEncode({
        'pluginId': pluginId,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
    
    if (response.statusCode != 200) {
      throw NetworkException('Failed to sync plugin data');
    }
  }
  
  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }
}
```

### 2. 创建认证服务

```dart
// lib/core/services/auth_service.dart
class AuthService {
  final NetworkManager _networkManager;
  User? _currentUser;
  
  AuthService(this._networkManager);
  
  Future<bool> login(String email, String password) async {
    try {
      final result = await _networkManager.login(email, password);
      if (result.isSuccess) {
        _currentUser = User.fromJson(result.data);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> logout() async {
    _currentUser = null;
    // 清除本地存储的认证信息
  }
  
  bool get isLoggedIn => _currentUser != null;
  User? get currentUser => _currentUser;
}
```

### 3. 创建插件商店UI

```dart
// lib/ui/screens/plugin_store_screen.dart
class PluginStoreScreen extends StatefulWidget {
  @override
  _PluginStoreScreenState createState() => _PluginStoreScreenState();
}

class _PluginStoreScreenState extends State<PluginStoreScreen> {
  List<PluginDescriptor> _storePlugins = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStorePlugins();
  }
  
  Future<void> _loadStorePlugins() async {
    try {
      final plugins = await NetworkManager().getStorePlugins();
      setState(() {
        _storePlugins = plugins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 显示错误消息
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plugin Store')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: _storePlugins.length,
              itemBuilder: (context, index) {
                final plugin = _storePlugins[index];
                return PluginStoreCard(
                  plugin: plugin,
                  onInstall: () => _installPlugin(plugin),
                );
              },
            ),
    );
  }
  
  Future<void> _installPlugin(PluginDescriptor plugin) async {
    try {
      await NetworkManager().installPlugin(plugin.id, plugin.version);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plugin ${plugin.name} installed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to install plugin: $e')),
      );
    }
  }
}
```

## 后端服务器示例 (Node.js + Express)

### 1. 基础服务器设置

```javascript
// server.js
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const multer = require('multer');

const app = express();
app.use(cors());
app.use(express.json());

// 数据库连接 (使用你喜欢的数据库)
const db = require('./database');

// 认证中间件
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.sendStatus(401);
  }
  
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// 认证路由
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  
  try {
    const user = await db.findUserByEmail(email);
    if (!user || !await bcrypt.compare(password, user.password)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const accessToken = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    res.json({
      accessToken,
      user: { id: user.id, email: user.email, username: user.username }
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// 插件商店路由
app.get('/api/plugins/store', async (req, res) => {
  try {
    const { category, search } = req.query;
    const plugins = await db.getStorePlugins({ category, search });
    res.json(plugins);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch plugins' });
  }
});

// 插件安装路由
app.post('/api/plugins/install', authenticateToken, async (req, res) => {
  try {
    const { pluginId, version } = req.body;
    await db.installPluginForUser(req.user.userId, pluginId, version);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Failed to install plugin' });
  }
});

// 数据同步路由
app.post('/api/sync/plugin-data', authenticateToken, async (req, res) => {
  try {
    const { pluginId, data, timestamp } = req.body;
    await db.syncPluginData(req.user.userId, pluginId, data, timestamp);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Failed to sync data' });
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

### 2. 数据库模型

```sql
-- users表
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- plugins表
CREATE TABLE plugins (
  id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  version VARCHAR(20) NOT NULL,
  type VARCHAR(20) NOT NULL,
  description TEXT,
  author VARCHAR(100),
  category VARCHAR(50),
  file_path VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- user_plugins表 (用户安装的插件)
CREATE TABLE user_plugins (
  user_id INTEGER REFERENCES users(id),
  plugin_id VARCHAR(100) REFERENCES plugins(id),
  installed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_enabled BOOLEAN DEFAULT true,
  PRIMARY KEY (user_id, plugin_id)
);

-- plugin_data表 (插件数据同步)
CREATE TABLE plugin_data (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  plugin_id VARCHAR(100),
  data JSONB,
  timestamp TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 部署建议

### 1. 后端部署
- 使用Docker容器化
- 配置HTTPS
- 设置数据库连接池
- 实现日志记录
- 配置监控和告警

### 2. 客户端配置
- 配置不同环境的API端点
- 实现离线模式支持
- 添加网络错误处理
- 实现数据缓存策略

这样您就可以构建一个完整的插件平台生态系统，支持插件的云端分发、用户管理和数据同步。