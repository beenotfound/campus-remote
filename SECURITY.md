# Security

## 威胁模型

这套东西的目标是：**让同一校园网内的 iPad 能控制宿舍电脑，同时不让校园网/公网直接扫到电脑端口。**

- 传输层：Tailscale 的 WireGuard，端到端加密（含视频/音频/输入）。
- 访问层：Windows 防火墙只允许 `100.64.0.0/10`；Sunshine Web UI 只监听本机。
- 认证层：Sunshine Web UI 密码 + Moonlight 配对 PIN（必须在本机输入）。

## 不会提交到仓库的内容

`.gitignore` 已排除：

- `config/`：包含 `admin.txt`（Sunshine 管理员密码）和 `config.json`（含 DuckDNS token）；
- `logs/`：可能包含 Tailscale 登录链接、IP、账号信息；
- `Downloads/`、`Sunshine/`、`Tailscale/`：安装包和二进制；
- `*.log`、`*.msi`、`*.exe`、`*.zip`、`*.dll`。

提交前请自查：

```powershell
git grep -nE "tskey-|admin\.txt|100\.[0-9]+\.[0-9]+\.[0-9]+|2001:db8:"
```

## 加固清单

- [ ] Tailscale 账号开启 2FA。
- [ ] Tailscale 后台开启 **Device approval**（新设备需审批）。
- [ ] 临时 auth key 用完后 **Revoke**。
- [ ] iPad 设置锁屏密码；丢失时在 Tailscale 后台移除设备、在 Sunshine 里移除配对、改密码。
- [ ] 如需更严格：配置 Tailscale ACL，只允许 iPad 访问电脑的 Moonlight 端口（见 `docs/安全加固.md`）。
- [ ] Sunshine / Tailscale 保持更新。
- [ ] 不要把 `config/config.json`、`config/admin.txt`、`logs/` 提交或外传。

## 报告问题

发现安全问题请开 issue，不要在公开 issue 里贴真实密钥、IP 或密码。
