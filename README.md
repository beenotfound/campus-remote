# Campus-Remote · 任意网络的远程串流（校园 / 家庭 / 公司）

把宿舍/实验室的 Windows 电脑，通过 **Tailscale + Sunshine + Moonlight** 串流到 iPad、手机或另一台电脑。适用于任何需要远程串流、又不想开公网端口的网络（校园网、家庭宽带、公司内网都可以）。

> 实测：同一校园网内电脑 ↔ iPad，直连 **9ms**，**2560×1600@60fps HEVC**，NVENC 硬编。

## 原理

```text
iPad (Moonlight) ── Tailscale 加密隧道 ──> 宿舍电脑 (Sunshine)
                         │
                  100.x.y.z（固定私网地址，免公网 IP）
```

- **Tailscale**：给电脑一个稳定的 `100.x` 地址，免公网 IP / DDNS / 端口映射；Tailscale 内自动直连，不走中转。
- **Sunshine**：电脑端抓屏 + NVENC/AMF/QSV 硬件编码 + 接收键鼠。
- **Moonlight**：iPad 端解码显示 + 回传触摸 / 键鼠 / 音频。

## 安全设计

- Windows 防火墙**只允许** `100.64.0.0/10`（Tailscale 私网）访问 Moonlight 端口，非 Tailscale 网络/公网扫不到。
- Sunshine Web UI（47990）仅本机可访问；配对 PIN 必须在本机输入。
- 串流走 WireGuard 端到端加密；可选 Tailscale ACL 进一步限制到单台 iPad。
- 详见 [docs/安全加固.md](docs/安全加固.md)。

## 设计取舍

- **不用 RDP**：Windows 家庭版没有 RDP 服务端；Sunshine 在家庭版可用。
- **不用向日葵/ToDesk 免费版**：走公网中继、有 1080p 限制；本方案是 NVENC 硬编 + Tailscale 直连。
- **用 Sunshine + Moonlight**：成熟的 GameStream 开源实现，支持 NVENC/AMF/QSV；Moonlight 在国区 App Store 免费。
- **用 Tailscale**：给电脑稳定的 `100.x` 地址，免公网 IP / DDNS / 端口映射；Tailscale 内自动直连；WireGuard 端到端加密。
- **防火墙只放行 `100.64.0.0/10`**：非 Tailscale 网络/公网扫不到端口；Web UI 仅本机；配对 PIN 必须本机输入。

## 适用范围

- **任何网络**：Tailscale 负责 NAT 穿透，不依赖校园网特权；校园网、家庭宽带、公司网络都可以。
- **校园网**：同一校园网内 Tailscale 通常自动直连，延迟低；离开校园用 4G/5G 也能连（中继兜底）。
- **直连 IPv6 兜底是可选的**：不同网络的 IPv6 前缀不同，把 `config/config.json` 的 `direct.allowedPrefixes` 改成你所在网络的 `/64`；脚本不硬编码任何学校的前缀。

## 前置条件

- Windows 10/11（**家庭版也可以**，不需要 RDP）。
- 支持硬件编码的 GPU（NVIDIA NVENC / AMD AMF / Intel QSV；NVIDIA 体验最好）。
- 一个 Tailscale 账号（Google / Microsoft / Apple 登录，免费个人版即可）。
- 客户端设备：iPad / iPhone / Android / Windows / macOS / Linux（见下方「支持的客户端」）。

## 支持的客户端

| 客户端 | Moonlight | Tailscale |
|---|---|---|
| iPad / iPhone | App Store（中国区可下） | App Store（**非中国区**） |
| Android | F-Droid / GitHub APK | Google Play / 官方 APK |
| Windows / macOS / Linux | 官方客户端 | 官方客户端 |

- **Android（国区没有 Google Play 也能装）**
  - Moonlight：F-Droid（包名 `com.limelight`）或 GitHub Releases 里的 `app-nonRoot-release.apk`。
  - Tailscale：官方 APK 页 `https://pkgs.tailscale.com/stable/#android`，或 GitHub Releases 里的 `tailscale-android-universal-*.apk`。
- 配对流程所有客户端一致：Moonlight 显示 4 位 PIN → 电脑运行 `配对.cmd` → 输入。
- 如果给 Tailscale 配了 ACL，记得把 Android 设备也加进 `src`。

## 快速开始

1. 把仓库克隆/下载到任意目录，例如 `D:\Campus-Remote`。
2. 右键 **`安装.cmd`** → 以管理员身份运行（安装 Sunshine + Tailscale，配置防火墙/电源，需 UAC）。
3. 登录 Tailscale：运行 **`登录Tailscale.cmd`**，或
   ```powershell
   tailscale up --auth-key=<YOUR_AUTH_KEY>
   ```
4. 客户端（iPad / Android / 电脑）：安装 Tailscale + Moonlight，登录**同一个 Tailscale 账号**。
5. 电脑运行 **`诊断.cmd`**，记下 `100.x.y.z`；Moonlight 里添加这个地址。
6. 运行 **`配对.cmd`**，把 iPad 上显示的 4 位 PIN 输入 Sunshine Web UI（`https://127.0.0.1:47990`）。
7. 完成，Moonlight 选 **Desktop** 即可。

## 目录结构

```text
安装.cmd / 诊断.cmd / 配对.cmd / 安全检查.cmd / 卸载.cmd ...
scripts/     PowerShell 脚本（安装、防火墙、睡眠守卫、DDNS、卸载等）
docs/        中文使用说明、故障排查、安全加固
config.example.json   配置模板（安装时复制为 config/config.json）
```

> 运行时生成、**不会提交**的目录：`config/`（含密码）、`logs/`、`Downloads/`、`Sunshine/`、`Tailscale/`。

## 日常使用

- iPad：开 Tailscale → 开 Moonlight → 点电脑 → Desktop。
- 电脑：插电、盖子保持打开；安装时不会自动注册唤醒/睡眠任务，需要时运行 `恢复自动唤醒.cmd`。
- `暂停远程访问.cmd` / `恢复远程访问.cmd`：一键停/开远程。
- `关闭自动唤醒.cmd` / `恢复自动唤醒.cmd`：切换定时唤醒/睡眠（睡眠任务带“串流中不睡”保护）。

## 直连兜底（可选）

如果需要脱离 Tailscale，可以走 IPv6 直连（可选）：

1. 在 https://www.duckdns.org 注册一个随机子域名；
2. 把子域名/token 填进 `config/config.json` 的 `direct` 段；
3. 运行 `scripts/ddns.ps1 -InstallTask`；
4. Moonlight 添加 `<子域名>.duckdns.org`；
5. 运行 `允许校园直连.cmd` 把所在网络的 `/64` 加进防火墙（见 `config.json` 的 `direct.allowedPrefixes`）。

> 直连模式的安全性低于 Tailscale（视频流不加密），只建议在 Tailscale 不可用时使用。

## 排错

见 [docs/故障排查.md](docs/故障排查.md)。常用：

- `诊断.cmd`：服务、Tailscale、编码器、防火墙、任务状态；
- `安全检查.cmd`：确认非 Tailscale 网络无法访问 Moonlight/Web UI 端口；
- `重启Sunshine.cmd`：重启被控端。

## 许可与致谢

- 本仓库的脚本和文档：**MIT**（见 `LICENSE`）。
- 第三方组件（Sunshine / Moonlight / Tailscale）**不由本仓库分发**，许可与来源详见 [THIRD_PARTY.md](THIRD_PARTY.md)。
- 安装脚本默认用国内镜像下载官方 release，可自行换成官方 GitHub 地址；不包含、不修改它们的源码。
- 协议源自 NVIDIA GameStream（由 Moonlight 社区实现，本仓库不含 NVIDIA 代码）。

## 免责声明

本项目与任何学校/公司无关；请遵守所在网络的管理规定；使用风险自负，作者不对数据丢失或安全问题负责。

## English (TL;DR)

A PowerShell kit to stream a Windows PC to an iPad over any network (campus, home, office) using **Tailscale + Sunshine + Moonlight**: no public IP, no port forwarding, WireGuard-encrypted, measured ~9 ms on direct paths. Windows firewall is scoped to the Tailscale CGNAT range only; the Sunshine web UI stays local. MIT licensed; Sunshine/Moonlight/Tailscale are separate GPL/BSD dependencies.
