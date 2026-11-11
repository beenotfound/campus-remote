# AGENTS.md · 阅读声明（AI Agent 版）

> 你是要在这个仓库里读代码、改脚本或执行安装的 AI Agent。**先读完本文件，再动手。**
> 这个仓库会改动一台真实 Windows 电脑的系统设置。安全 > 功能 > 便利。

## 1. 这个仓库是什么

Campus-Remote 是一套 **Windows PowerShell 自动化脚本**，把电脑配置成：

- **Sunshine**：被控端（抓屏 + NVENC/AMF/QSV 硬件编码 + 接收键鼠）；
- **Tailscale**：私有网络（`100.x` 固定地址，免公网 IP / DDNS / 端口映射）；
- **Moonlight**：iPad / Android / 手机端客户端（解码显示 + 回传输入）。

仓库只包含原创脚本与文档（MIT）。Sunshine / Moonlight / Tailscale 是独立项目，**不随本仓库分发**。

## 2. 不可破坏的安全不变量（硬约束）

1. Sunshine 的 Moonlight 端口（TCP `47984/47989/48010`，UDP `47998–48002`）**只能**对 `100.64.0.0/10` 开放。
2. **Sunshine Web UI（47990）绝不能对网络开放**；`origin_web_ui_allowed` 必须保持 `pc`。
3. 不得把 UPnP、端口映射、公网 DDNS 加进默认路径（直连兜底只能是可选，且需显式开启）。
4. 不得把 `config/`、`logs/`、`Downloads/`、`Sunshine/`、`Tailscale/`、安装包、密钥、密码提交进仓库。
5. 不得把 Sunshine / Moonlight 的二进制或修改版源码打包进仓库（GPLv3 义务）。
6. 不得加入遥测、上报，或除官方下载之外的网络请求。
7. 修改防火墙 / 电源 / 计划任务时，**默认必须保持 Tailscale-only**；校园 `/64` 白名单只能是可选的直连兜底。

如果你要改动以上任何一条，先停下来，向维护者说明理由。

## 3. 代码约定

- 目标运行时：**Windows PowerShell 5.1**（Win10/11 自带）。不要用 PS7 专属语法。
- **所有 `.ps1` 必须是 UTF-8 with BOM**：脚本含中文，PS 5.1 会把无 BOM 的 UTF-8 当 ANSI，直接解析失败。
- 路径统一用 `$root = Split-Path $PSScriptRoot -Parent`（脚本位于 `<root>\scripts`）。**不要硬编码** `D:\Campus-Remote` 或用户名。
- `.cmd` 启动器用 `%~dp0` 相对路径。
- 需要管理员权限的步骤：脚本自行 `Start-Process -Verb RunAs` 提权，输出写入 `<root>\logs\`。
- 保持**幂等**：重复运行不应破坏已有配置。
- 避开 PowerShell 保留变量/别名：`$pid`、`$host`、`$input`、`R`（`Invoke-History` 的别名）等。
- 计划任务用 `-User 'NT AUTHORITY\SYSTEM'`（不是 `'SYSTEM'`）。
- 兼容 Windows 家庭版（无 RDP 服务端）、Modern Standby、UAC。

## 4. 改完必须做的验证

- **语法**：每个 `.ps1` 过一遍
  ```powershell
  $err = $null
  [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$err)
  ```
- **防火墙**：`Get-NetFirewallRule -DisplayName 'Campus-Remote *'` 只应出现 `100.64.0.0/10`；Sunshine 自带规则应为 Disabled。
- **Tailscale**：`tailscale status` 正常、`tailscale ip -4` 有 `100.x`（若已登录）。
- **敏感串**：不得出现真实 `tskey-`、密码、真实 `100.x` / 校园 IP。
- 不要在没有用户同意的情况下运行安装器、改防火墙、重启服务，或动 `D:\Campus-Remote` 这个**正在使用的安装**。

## 5. 目录结构

```text
安装.cmd / 诊断.cmd / 配对.cmd / 安全检查.cmd / 卸载.cmd ...   启动器（%~dp0）
scripts/      PowerShell 脚本
docs/         使用说明、故障排查、安全加固
config.example.json   安装时复制为 config/config.json
THIRD_PARTY.md        第三方组件许可
SECURITY.md           威胁模型与加固
```

运行时生成、**被 .gitignore 排除**：`config/`、`logs/`、`Downloads/`、`Sunshine/`、`Tailscale/`。

## 6. 已知坑（本项目踩过的）

- Tailscale 在线安装器是 WiX Burn，会从 CloudFront 拉 MSI；校园 IPv6 到 CloudFront 可能极慢/卡住 → 直接用 MSI 走 IPv4。
- Sunshine MSI 用 `INSTALL_ROOT=...` 指定目录；Tailscale MSI 用 `INSTALLDIR=...`。
- Sunshine 首次凭据通过 `POST /api/password` 创建；Web UI 使用 HTTP Basic Auth。
- Tailscale `1.104.6` 的 CLI 不支持 `tailscale set --operator=...`。
- `Get-ScheduledTask` 在非管理员上下文可能看不到 SYSTEM 任务。
- 睡眠任务必须调用 `sleep-if-idle.ps1`，不能直接 `rundll32`，否则会在串流中把电脑睡掉。
- 仓库文件名含中文；Git 里显示为转义序列是正常的。

## 7. 许可

- 本仓库：**MIT**（见 `LICENSE`）。
- Sunshine / Moonlight：**GPLv3**（不随仓库分发）。
- Tailscale：**BSD-3-Clause**。
- 详见 `THIRD_PARTY.md`。

## 8. 不确定时

停下来，问维护者。不要用“先跑通再说”的方式绕过上面的安全约束。
