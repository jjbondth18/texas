# Texas Local Admin — SSH deployment

Admin 后端运行在 Google Cloud VM 上，直接打开 VM 本机的生产 SQLite 文件，并且只监听 `127.0.0.1:8787`。Windows 端不运行 Node、不读取数据库，也不挂载远程文件；它只建立 SSH HTTP 端口隧道：

```text
ssh -N -T -L <local-port>:127.0.0.1:<remote-port> user@server
```

## 云服务器端

以下示例假设仓库位于 `/opt/texas`。按实际路径调整：

```bash
cd /opt/texas/server
npm ci
npm run build

cd /opt/texas/tools/admin
cp .env.server.example .env.server
chmod 600 .env.server
nano .env.server
```

必须设置：

- `ADMIN_HOST=127.0.0.1`
- `ADMIN_PIN`：至少 6 字符
- `SQLITE_PATH`：现有生产 SQLite 的绝对路径
- `ADMIN_BACKUP_DIR`：预迁移及手动备份的绝对目录
- `ADMIN_WEB_ROOT`：仓库内 `tools/admin/web` 的绝对路径

游戏服务与 Admin 的 `SQLITE_PATH` 必须解析到完全相同的文件。两者都启用 WAL、foreign keys 和默认 5000ms `busy_timeout`。Admin 启动时拒绝相对路径、缺失文件、临时目录及明显的 test/smoke/tmp 数据库；不会自动创建生产数据库。每次启动会先通过 SQLite 在线 backup API 创建 `pre-migration-*.sqlite`，迁移失败则停止启动。

直接运行：

```bash
cd /opt/texas
chmod +x tools/admin/scripts/start-admin-server.sh
tools/admin/scripts/start-admin-server.sh
```

验证：

```bash
ss -lntp | grep 8787
curl --fail http://127.0.0.1:8787/health
```

监听地址必须只有 `127.0.0.1:8787`。Health 仅返回：

```json
{"ok":true,"service":"texas-admin","databaseConnected":true}
```

可选 PM2：

```bash
cd /opt/texas
pm2 start tools/admin/ecosystem.admin.config.cjs
pm2 save
pm2 status texas-admin
```

进程名固定为 `texas-admin`，与游戏进程 `texas-server` 分开。状态页只查询这两个固定进程，并最多读取配置中两个固定日志文件末尾 80 行；没有任意 shell、进程名或日志路径输入。

## Windows 客户端

```powershell
Copy-Item .\tools\admin\.env.client.example .\tools\admin\.env.client
notepad .\tools\admin\.env.client
```

设置 `SSH_HOST`、`SSH_USER`、`SSH_KEY_PATH`，然后双击 `start-admin.bat` 或运行：

```powershell
.\tools\admin\start-admin.ps1
```

脚本检查本地端口、调用 Windows OpenSSH、等待 `http://127.0.0.1:8787/health` 成功后打开浏览器。关闭窗口或按 Ctrl+C 会结束 SSH 进程。实际转发参数固定为：

```text
-L ADMIN_LOCAL_PORT:127.0.0.1:ADMIN_REMOTE_PORT
```

它不会转发 SQLite、不会启动本地 Admin Node 服务，也不会修改云防火墙。

## 网络与数据库安全

- Google Cloud 防火墙不需要开放 8787。
- SQLite 不需要也不存在公网数据库端口。
- 没有 VM SSH 权限的设备无法建立 Admin 隧道。
- 不要用 SSHFS、SMB、网络共享或“下载—修改—覆盖”方式写生产 SQLite。
- 生产文件始终由 VM 本机上的 Admin 与游戏服务共同访问；短事务、WAL 和 busy timeout 负责单机并发协调。
- 备份使用 SQLite 官方在线备份机制，不把普通文件复制作为活动数据库备份方案。

## 页面能力与已知数据限制

保留 Dashboard、玩家、Chip/Gem/XP、Daily Bonus、ban/unban、备注、钱包流水、审计、Matches、Replays 和备份。列表 API 每页固定 100 行并支持 `?page=`。PM2 未安装时状态明确显示 `unavailable`。现有 Replay schema 没有 preview/blob 列，后台不会读取或展示 `replay_keys.key_material`。

真实 VM 首次部署后仍需人工执行本文的 `ss`、`curl`、PM2 和 SSH 隧道验证；仓库测试不会声称替代真实云端网络验证。
