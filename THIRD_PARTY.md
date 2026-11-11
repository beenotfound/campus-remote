# Third-Party Components / 第三方组件

This repository contains **only original PowerShell scripts, launchers and documentation** (licensed MIT, see `LICENSE`).

It does **not** bundle or redistribute the following projects. They are downloaded from their official sources at install time, or installed separately by the user.

| Component | License | Role | Official source |
|---|---|---|---|
| Sunshine | GPL-3.0 | Windows host: capture + hardware encode | https://github.com/LizardByte/Sunshine |
| Moonlight | GPL-3.0 | iOS / iPadOS client: decode + input | https://github.com/moonlight-stream |
| Tailscale | BSD-3-Clause | WireGuard mesh / private network | https://tailscale.com |
| GameStream protocol | Implemented by Moonlight (no NVIDIA code included) | Streaming protocol | https://github.com/moonlight-stream/moonlight-common-c |

## Notes

- **GPL-3.0**: if you redistribute Sunshine/Moonlight binaries or modified source, you must comply with GPL-3.0 (provide source and license). This repository does **not** distribute them; the installer script downloads the official release via a China-friendly mirror URL; replace it with the official GitHub URL if you prefer.
- **Trademarks**: "Sunshine", "Moonlight", "Tailscale" are used only to refer to those projects. This project is **not affiliated with or endorsed by** any university, LizardByte, Moonlight, Tailscale, or NVIDIA.
- **No warranty**: see `LICENSE`.
