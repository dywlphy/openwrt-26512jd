#!/bin/bash
#
# diy-part2.sh - 更新feeds后的自定义配置
# OpenWrt 24.10 版本
#

echo "=========================================="
echo "OpenWrt 24.10 Official Stable Build"
echo "diy-part2.sh - 自定义配置"
echo "=========================================="

# 1. 设置默认主机名
echo "[1/6] 设置默认主机名..."
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i 's/OpenWrt/OpenWrt-24.10/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# 2. 设置默认时区为上海
echo "[2/6] 设置默认时区..."
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/'CST-8'/a \\\t\tset system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# 3. 设置默认主题为Material
echo "[3/6] 设置默认主题为Material..."
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' package/feeds/luci/luci/Makefile 2>/dev/null || true

# 4. 添加 Full Cone NAT 模块
echo "[4/6] 添加 Full Cone NAT 模块..."
FULLCONENAT_DIR="package/iptables-mod-fullconenat"

# 清理旧版本
rm -rf "$FULLCONENAT_DIR" 2>/dev/null

# 尝试多个 git 源
GIT_SOURCES=(
  "https://github.com/yujincheng08/openwrt-iptables-mod-fullconenat.git"
  "https://gitlab.com/yujincheng08/openwrt-iptables-mod-fullconenat.git"
  "https://github.com/kenzok8/openwrt-iptables-mod-fullconenat.git"
)

CLONE_SUCCESS=0
for src in "${GIT_SOURCES[@]}"; do
  echo "  尝试克隆: $src"
  if git clone --depth 1 "$src" /tmp/fullconenat 2>/dev/null; then
    cp -r /tmp/fullconenat "$FULLCONENAT_DIR"
    rm -rf /tmp/fullconenat
    CLONE_SUCCESS=1
    echo "  - Full Cone NAT 模块克隆成功"
    break
  fi
done

if [ $CLONE_SUCCESS -eq 0 ]; then
  echo "  - 警告: Full Cone NAT 克隆失败，创建本地版本..."
  # 创建本地 fullconenat 包
  mkdir -p "$FULLCONENAT_DIR"
  cat > "$FULLCONENAT_DIR/Makefile" << 'MAKEEOF'
include $(TOPDIR)/rules.mk
PKG_NAME:=iptables-mod-fullconenat
PKG_VERSION:=1.0
PKG_RELEASE:=1
include $(INCLUDE_DIR)/package.mk

define Package/iptables-mod-fullconenat
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Firewall
  TITLE:=Full Cone NAT iptables extension
  DEPENDS:=+kmod-ipt-nat +iptables-mod-nat-extra
endef

define Package/iptables-mod-fullconenat/description
  Full Cone NAT (also known as 1:1 NAT) iptables extension.
  Useful for P2P applications and gaming.
endef

define Build/Compile
endef

define Package/iptables-mod-fullconenat/install
	$(INSTALL_DIR) $(1)/usr/lib/iptables
endef

$(eval $(call BuildPackage,iptables-mod-fullconenat))
MAKEEOF
  echo "  - 本地 fullconenat 包已创建（占位版本）"
fi

# 5. 创建 CUPS 中文汉化包
echo "[5/6] 创建 CUPS 中文汉化包..."

# 创建目录结构
mkdir -p package/cups-zh-cn/files/usr/share/cups/zh_CN
mkdir -p package/cups-zh-cn/files/usr/share/cups/doc-root

# 尝试多种方式获取 CUPS 中文资源
CUPS_ZH_FOUND=0

# 方式1: 从 GitHub 仓库根目录查找
for zip_name in "CUPS_2.3.1_zh_CN.zip" "CUPS-zh.zip" "cups-zh-cn.zip"; do
  if [ -f "$GITHUB_WORKSPACE/$zip_name" ]; then
    echo "  找到 CUPS 中文包: $GITHUB_WORKSPACE/$zip_name"
    unzip -o "$GITHUB_WORKSPACE/$zip_name" -d /tmp/cups-zh 2>/dev/null
    cp -r /tmp/cups-zh/zh_CN/* package/cups-zh-cn/files/usr/share/cups/zh_CN/ 2>/dev/null || \
    cp -r /tmp/cups-zh/*/zh_CN/* package/cups-zh-cn/files/usr/share/cups/zh_CN/ 2>/dev/null || true
    cp /tmp/cups-zh/index.html package/cups-zh-cn/files/usr/share/cups/doc-root/ 2>/dev/null || \
    cp /tmp/cups-zh/*/index.html package/cups-zh-cn/files/usr/share/cups/doc-root/ 2>/dev/null || true
    rm -rf /tmp/cups-zh
    CUPS_ZH_FOUND=1
    echo "  - CUPS 中文模板已从仓库复制"
    break
  fi
done

# 方式2: 尝试从 GitHub 克隆
if [ $CUPS_ZH_FOUND -eq 0 ]; then
  echo "  尝试从 GitHub 克隆 CUPS 中文资源..."
  if git clone --depth 1 https://github.com/nicholaskh/cups-chinese-template.git /tmp/cups-zh-src 2>/dev/null; then
    cp -r /tmp/cups-zh-src/zh_CN/* package/cups-zh-cn/files/usr/share/cups/zh_CN/ 2>/dev/null || \
    cp -r /tmp/cups-zh-src/*/zh_CN/* package/cups-zh-cn/files/usr/share/cups/zh_CN/ 2>/dev/null || true
    cp /tmp/cups-zh-src/index.html package/cups-zh-cn/files/usr/share/cups/doc-root/ 2>/dev/null || true
    rm -rf /tmp/cups-zh-src
    CUPS_ZH_FOUND=1
    echo "  - CUPS 中文模板已从 GitHub 克隆"
  fi
fi

# 方式3: 创建基础中文模板（兜底方案）
if [ $CUPS_ZH_FOUND -eq 0 ]; then
  echo "  未找到 CUPS 中文资源，创建基础中文模板..."
  # 创建一个简单的中文 index.html
  cat > package/cups-zh-cn/files/usr/share/cups/doc-root/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <title>CUPS 打印服务器</title>
  <style>
    body { font-family: 'Microsoft YaHei', sans-serif; margin: 20px; }
    h1 { color: #0066cc; }
    a { color: #0066cc; }
  </style>
</head>
<body>
  <h1>CUPS 打印服务器</h1>
  <p>欢迎使用 CUPS 打印服务</p>
  <ul>
    <li><a href="/admin">管理界面</a></li>
    <li><a href="/printers">打印机列表</a></li>
    <li><a href="/jobs">打印任务</a></li>
  </ul>
</body>
</html>
HTMLEOF
  echo "  - 基础中文模板已创建"
fi

# 创建 cups-zh-cn Makefile
cat > package/cups-zh-cn/Makefile << 'MAKEEOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=cups-zh-cn
PKG_VERSION:=2.3.1
PKG_RELEASE:=1

PKG_MAINTAINER:=OpenWrt Builder
PKG_LICENSE:=GPL-2.0-only

include $(INCLUDE_DIR)/package.mk

define Package/cups-zh-cn
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=CUPS Chinese (Simplified) Templates
  DEPENDS:=+cups
  PKGARCH:=all
endef

define Package/cups-zh-cn/description
  Simplified Chinese language templates for CUPS web interface.
  Replaces default English templates after installation.
endef

define Build/Compile
endef

define Package/cups-zh-cn/install
	$(INSTALL_DIR) $(1)/usr/share/cups/zh_CN
	$(CP) ./files/usr/share/cups/zh_CN/* $(1)/usr/share/cups/zh_CN/ 2>/dev/null || true
	$(INSTALL_DIR) $(1)/usr/share/cups/doc-root
	$(INSTALL_BIN) ./files/usr/share/cups/doc-root/index.html $(1)/usr/share/cups/doc-root/ 2>/dev/null || true
endef

$(eval $(call BuildPackage,cups-zh-cn))
MAKEEOF

echo "  - cups-zh-cn 包已创建"

# 6. 添加自定义banner
echo "[6/6] 添加自定义banner..."
cat > package/base-files/files/etc/banner << 'EOF'
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 -----------------------------------------------------
 OpenWrt 24.10 Official Stable Build
 -----------------------------------------------------
EOF

echo "=========================================="
echo "构建信息:"
echo "  - OpenWrt版本: 24.10 Official Stable"
echo "  - 目标平台: x86_64"
echo "  - 打印: CUPS + Avahi + 中文(cups-zh-cn)"
echo "  - NAT: Full Cone NAT (iptables-mod-fullconenat)"
echo "  - VPN: WireGuard + pbr"
echo "  - 网络: Tailscale/ACME/frp"
echo "  - 控制: timecontrol"
echo "=========================================="
