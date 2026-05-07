# OpenWrt 官方 24.10 编译总结

## 一、最终成果

| 项目 | 状态 |
|------|------|
| CUPS 打印服务 | ✅ http://192.168.1.1:631/printers/ 正常运行 |
| ksmbd 文件共享 | ✅ 编译进固件 |
| SSR-Plus 科学上网 | ✅ 编译进固件 |
| WireGuard VPN | ✅ 编译进固件 |
| KMS 激活服务 | ✅ 编译进固件 |
| 固件大小 | 40.4 MB（squashfs 压缩后） |
| rootfs 上限 | 512 MB |

## 二、待修复小问题

| 问题 | 解决方法 |
|------|----------|
| LuCI 界面缺失主题 | SSH 执行 `opkg update && opkg install luci-theme-bootstrap` |
| GRUB 等待 5 秒 | 见下方「下次编译前建议的修改」 |

## 三、踩过的坑及解决办法

### 坑 1：diy-part2.sh 执行时机错误（最关键的坑）
- **现象**：CUPS、ksmbd、SSR-Plus 全部 `# ... is not set`
- **原因**：`diy-part2.sh` 在 `feeds update/install` 之前执行，里面 `feeds install -f` 找不到包
- **解决**：将 `./diy-part2.sh` 移到 `feeds install -a` **之后**执行

### 坑 2：check_config 函数 return 1 导致脚本崩溃
- **现象**：`##[error]Process completed with exit code 1`，即使只是检查失败也中断流程
- **原因**：`shell: bash -e {0}` 模式下，函数 `return 1` 被视为致命错误
- **解决**：将所有 `return 1` 改为 `return 0`，仅设置 `FAIL=1` 标记

### 坑 3：第三方包依赖缺失导致 defconfig 丢弃配置
- **现象**：`config.txt` 写的 `CONFIG_PACKAGE_cups=y` 在 `make defconfig` 后变成 `# ... is not set`
- **原因**：包的某些依赖（如 `cups-bjnp`、`ghostscript`）未满足，`make defconfig` 自动禁用
- **解决**：增加 **Force enable key packages** 步骤，用 `sed` 强行启用，并在 `.config` 中追加缺失包名

### 坑 4：mosdns Go 版本不兼容
- **现象**：`go: ../../go.mod requires go >= 1.25.0 (running go 1.23.12)`
- **原因**：GitHub Actions 的 `ubuntu-22.04` 自带 Go 1.23，mosdns 需要 1.25
- **解决**：在 **Force enable key packages** 中用 `sed` 禁用 mosdns 和相关选项

### 坑 5：固件镜像打包失败（Error 2 in target/linux/image）
- **现象**：编译到最后阶段 `target/linux failed to build`
- **原因**：CUPS 全家桶（ghostscript + gutenprint + foomatic-db）体积过大，默认 256MB rootfs 放不下
- **解决**：在 `config.txt` 中设置 `CONFIG_TARGET_ROOTFS_PARTSIZE=512`

### 坑 6：包名与 OpenWrt Kconfig 符号不一致
- **现象**：`CONFIG_PACKAGE_libfreetype=y` 不生效
- **原因**：
  - OpenWrt 包名 `freetype`，不是 `libfreetype`
  - `libusb-1.0` 写作 `libusb-1_0`
  - `libexpat` 写作 `expat`
- **解决**：修正 `config.txt` 中的包名

### 坑 7：diy-part2.sh 最后的 feeds install -f -p smpackage 整行失败
- **现象**：`WARNING: No feed for package 'cups-bjnp' found` 等五个包找不到
- **原因**：`cups-bjnp`、`ghostscript` 等在官方 `packages` feed 中，不在 `smpackage`
- **解决**：拆成两步——官方 packages 装扩展包，smpackage 装核心包

### 坑 8：LuCI 界面无法渲染
- **现象**：`Failed to load template 'themes/bootstrap/header.htm': No such file or directory`
- **原因**：`luci-theme-bootstrap` 没有被选入编译
- **解决**：见下方「下次编译前建议的修改」

## 四、最终文件清单

| 文件 | 路径 | 作用 |
|------|------|------|
| `build-official.yml` | `.github/workflows/` | 编译流程：feeds 顺序、冲突包清理、强制启用/禁用包、三道检查 |
| `config.txt` | 仓库根目录 | 包选择配置：CUPS、ksmbd、SSR-Plus、WireGuard、KMS、固件大小限制 |
| `diy-part1.sh` | 仓库根目录 | 添加第三方 feeds 源 |
| `diy-part2.sh` | 仓库根目录 | 自启动脚本、自动共享探测、CUPS 包双源安装 |

## 五、致谢

感谢以下开源项目及社区：

- [OpenWrt](https://openwrt.org/) 官方团队提供稳定的 24.10 编译框架
- [SSR-Plus](https://github.com/fw876/helloworld) 科学上网插件
- [CUPS](https://www.cups.org/) 打印服务及相关包维护者
- [ksmbd](https://www.samba.org/ksmbd/) 文件共享服务
- GitHub Actions 提供的免费编译资源
- 所有在踩坑过程中提供解决方案的社区开发者

## 六、下次编译前建议的修改

### 1. GRUB 超时设置
```bash
CONFIG_GRUB_TIMEOUT=1
CONFIG_GRUB_TIMEOUT_MINIMUM=1
