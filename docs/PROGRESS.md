# 项目进度

日期：2026-05-11  
项目：Vibe IM，飞书类全栈 IM MVP

## 当前阶段

正在推进全栈 MVP。前端已具备类飞书三栏消息界面、顶部搜索、会话切换、消息发送、通讯录页面、本地后端优先读取和 mock fallback。后端已具备 FastAPI + SQLite 本地服务、会话 API、消息 API、会话搜索、联系人 API 和烟测脚本。

## 已完成

- Flutter 项目初始化。
- 类飞书桌面端三栏消息界面。
- 顶部全局搜索框。
- 会话列表、聊天详情、消息输入区。
- 后端 FastAPI 应用。
- SQLite 本地数据库 `backend/data/vibe_im.sqlite3`。
- 会话表和消息表。
- 会话列表、会话搜索、消息列表、发送消息、清除未读 API。
- Flutter 前端接入本地 API，并保留 mock fallback。
- 后端烟测脚本 `backend/scripts/smoke_test.py`。
- 联系人表和联系人 API。
- 通讯录页面，支持联系人列表、搜索和详情展示。

## 本轮目标

本轮推进通讯录模块的全栈 MVP：

1. 后端新增联系人表和联系人 API。已完成
2. 前端新增通讯录页面，替换当前“模块建设中”占位。已完成
3. 通讯录支持联系人列表、搜索、基础详情。已完成
4. 更新烟测脚本和文档。已完成
5. 运行前后端验证并重建 Web 预览产物。已完成

## 本轮结果

- 后端新增 `contacts` 表，已兼容既有 SQLite 数据库自动建表和 seed。
- 后端新增 `GET /api/contacts` 和 `GET /api/contacts/{contact_id}`。
- 通讯录导航已从占位页升级为真实页面。
- 通讯录支持联系人列表、全局搜索联动、联系人详情。
- 通讯录具备后端优先、mock fallback 的运行策略。
- 后端烟测已覆盖联系人列表和联系人搜索。
- Widget 测试已覆盖通讯录导航打开。

## 最近一次验证

已通过：

```bash
backend/.venv/bin/python backend/scripts/smoke_test.py
backend/.venv/bin/python -m compileall backend/app backend/scripts
dart format lib test
flutter analyze
flutter test
flutter build web
```

当前预览：

- 前端：http://127.0.0.1:8080
- 后端：http://127.0.0.1:8000/docs

## 下一步建议

1. 打通“联系人详情 -> 发消息”：点击发消息后跳转到对应会话。
2. 新增联系人创建 API 和弹窗表单。
3. 将全局搜索扩展为统一结果面板，聚合会话和联系人。
4. 增加 WebSocket 连接管理骨架。
5. 补充数据库迁移脚本，替代当前轻量自动建表方式。

## 风险审查

- 风险：直接做完整组织架构会拖慢 MVP。
- 修正：本轮只做联系人数据表、联系人列表、搜索和详情，为后续组织架构树预留字段。
- 风险：已有本地数据库不会重新 seed 新表。
- 修正：数据库初始化需要对 contacts 表单独判断并 seed，不能依赖 conversations 表是否为空。
- 风险：前端通讯录强依赖后端会影响预览。
- 修正：通讯录同样保留本地 fallback 数据。

## 验证命令

```bash
backend/.venv/bin/python backend/scripts/smoke_test.py
backend/.venv/bin/python -m compileall backend/app backend/scripts
dart format lib test
flutter analyze
flutter test
flutter build web
```
