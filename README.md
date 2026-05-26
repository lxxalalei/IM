# Vibe IM

飞书类 IM 产品原型，使用 Flutter 开发。

当前阶段：Milestone 2，全栈 MVP 搭建中。前端已完成桌面端三栏消息界面、顶部搜索、通讯录页面，后端已接入本地 FastAPI + SQLite。

## 文档

- [PRD](docs/PRD.md)
- [项目工作规则](docs/WORKING_RULES.md)

## 本地运行

当前环境使用 Flutter stable 3.41.9。

```bash
export PATH="$HOME/flutter/bin:$PATH"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"

flutter pub get
flutter run -d web-server
```

## Windows 打包

Windows `.exe` 需要在 Windows 构建环境中生成。项目提供了打包脚本：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows_release.ps1
```

离线 Windows 机器上构建时，先准备好 Flutter SDK 和 pub 缓存，然后执行：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows_release.ps1 -Offline
```

打包产物会输出到：

- `dist\vibe_im_windows_release\feishu_im.exe`
- `dist\vibe_im_windows_release.zip`

如果使用 GitHub Actions，可以手动运行 `Build Windows Release` workflow，并下载
`vibe_im_windows_release` artifact。

## 后端运行

后端使用 FastAPI + SQLite，数据库文件保存在本机 `backend/data/vibe_im.sqlite3`。

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

启动后可访问：

- API 健康检查：http://127.0.0.1:8000/health
- API 文档：http://127.0.0.1:8000/docs

也可以先构建 Web 产物并用静态服务预览：

```bash
flutter build web
python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web
```

## 验证

```bash
dart format lib test
flutter analyze
flutter test
flutter build web
```

后端服务启动后可运行：

```bash
cd backend
.venv/bin/python scripts/smoke_test.py
```
