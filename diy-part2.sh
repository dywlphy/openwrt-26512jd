#!/bin/bash
#
# diy-part2.sh - 更新feeds后的自定义配置
# OpenWrt 24.10 版本
# 功能：CUPS汉化 + Full Cone NAT + NAT检测
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

# 4. 添加自定义banner + 创建 cups-zh-cn 汉化包
echo "[4/6] 添加banner和CUPS汉化包..."

# 自定义banner
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

# 创建 cups-zh-cn 自定义包目录
mkdir -p package/cups-zh-cn/files/usr/share/cups/templates/zh_CN
mkdir -p package/cups-zh-cn/files/usr/share/cups/doc-root/zh_CN

# 从GitHub直接clone CUPS汉化项目
CUPS_CLONE_OK=false
echo "  - 正在从GitHub下载CUPS中文汉化包..."
git clone --depth 1 https://github.com/yanzilisan183/CUPS_LanguagePackage_zh_CN.git /tmp/cups-zh-repo 2>/dev/null && CUPS_CLONE_OK=true

if [ "$CUPS_CLONE_OK" = true ] && [ -d /tmp/cups-zh-repo ]; then
    if [ -d /tmp/cups-zh-repo/templates/zh_CN ]; then
        cp -r /tmp/cups-zh-repo/templates/zh_CN/* package/cups-zh-cn/files/usr/share/cups/templates/zh_CN/
        TMPL_COUNT=$(find package/cups-zh-cn/files/usr/share/cups/templates/zh_CN/ -type f | wc -l)
        echo "  - Web界面模板已复制 ($TMPL_COUNT 个文件)"
    fi
    if [ -d /tmp/cups-zh-repo/doc-root/zh_CN ]; then
        cp -r /tmp/cups-zh-repo/doc-root/zh_CN/* package/cups-zh-cn/files/usr/share/cups/doc-root/zh_CN/
        DOC_COUNT=$(find package/cups-zh-cn/files/usr/share/cups/doc-root/zh_CN/ -type f | wc -l)
        echo "  - 帮助文档已复制 ($DOC_COUNT 个文件)"
    fi
    rm -rf /tmp/cups-zh-repo
else
    echo "  - 警告: GitHub clone失败，CUPS汉化包将为空"
    WORKSPACE_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
    if [ -f "$WORKSPACE_DIR/CUPS_2.3.1_zh_CN.zip" ]; then
        echo "  - 发现本地CUPS_2.3.1_zh_CN.zip，尝试解压..."
        unzip -o "$WORKSPACE_DIR/CUPS_2.3.1_zh_CN.zip" -d /tmp/cups-zh 2>/dev/null
        cp -r /tmp/cups-zh/zh_CN/* package/cups-zh-cn/files/usr/share/cups/templates/zh_CN/ 2>/dev/null || true
        cp -r /tmp/cups-zh/index.html package/cups-zh-cn/files/usr/share/cups/doc-root/zh_CN/ 2>/dev/null || true
        rm -rf /tmp/cups-zh
    fi
fi

# cups-zh-cn Makefile
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
  Includes 58 web templates and Chinese help documents.
  Source: https://github.com/yanzilisan183/CUPS_LanguagePackage_zh_CN
endef

define Build/Compile
endef

define Package/cups-zh-cn/install
	$(INSTALL_DIR) $(1)/usr/share/cups/templates/zh_CN
	$(CP) ./files/usr/share/cups/templates/zh_CN/* $(1)/usr/share/cups/templates/zh_CN/
	$(INSTALL_DIR) $(1)/usr/share/cups/doc-root/zh_CN
	$(CP) ./files/usr/share/cups/doc-root/zh_CN/* $(1)/usr/share/cups/doc-root/zh_CN/
endef

define Package/cups-zh-cn/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	[ -d /usr/share/cups/templates/zh_CN ] && {
		cp -rf /usr/share/cups/templates/zh_CN/* /usr/share/cups/templates/
		rm -rf /usr/share/cups/templates/zh_CN
	}
	[ -d /usr/share/cups/doc-root/zh_CN/help ] && {
		[ -L /usr/share/cups/doc-root/help ] && rm -f /usr/share/cups/doc-root/help
		[ -d /usr/share/cups/doc-root/help ] && mv /usr/share/cups/doc-root/help /usr/share/cups/doc-root/help_en
		ln -sf /usr/share/cups/doc-root/zh_CN/help /usr/share/cups/doc-root/help
	}
	cat > /etc/cups/cupsd.conf << 'CONF'
Listen *:631
Listen /var/run/cups/cups.sock
LogLevel warn
AccessLog /var/log/cups/access_log
ErrorLog /var/log/cups/error_log
DefaultPolicy default

<Location />
  Order allow,deny
  Allow @LOCAL
</Location>

<Location /admin>
  Order allow,deny
  Allow @LOCAL
</Location>

<Location /admin/conf>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow @LOCAL
</Location>

<Location /printers>
  Order allow,deny
  Allow @LOCAL
</Location>

Browsing On
BrowseLocalProtocols dnssd
CONF
	mkdir -p /etc/avahi/services
	cat > /etc/avahi/services/cups.service << 'AVAHI'
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">CUPS 打印服务器 @ %h</name>
  <service>
    <type>_ipp._tcp</type>
    <port>631</port>
    <txt-record>txtvers=1</txt-record>
    <txt-record>qtotal=1</txt-record>
    <txt-record>rp=printers/</txt-record>
  </service>
</service-group>
AVAHI
	[ -x /etc/init.d/avahi-daemon ] && /etc/init.d/avahi-daemon restart 2>/dev/null
	[ -x /etc/init.d/cupsd ] && /etc/init.d/cupsd restart 2>/dev/null
}
exit 0
endef

define Package/cups-zh-cn/postrm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	[ -x /etc/init.d/cupsd ] && /etc/init.d/cupsd restart 2>/dev/null
}
exit 0
endef

$(eval $(call BuildPackage,cups-zh-cn))
MAKEEOF

echo "  - cups-zh-cn 包已创建"

# 5. 添加 fullconenat 全锥形NAT模块
echo "[5/6] 添加Full Cone NAT模块..."
git clone --depth 1 https://github.com/yujincheng08/openwrt-iptables-mod-fullconenat.git /tmp/fullconenat 2>/dev/null
if [ -d /tmp/fullconenat/iptables-mod-fullconenat ]; then
    cp -r /tmp/fullconenat/iptables-mod-fullconenat package/
    echo "  - fullconenat模块已添加"
else
    echo "  - 警告: fullconenat克隆失败，尝试备用源..."
    git clone --depth 1 https://github.com/LGA1150/openwrt-fullconenat.git /tmp/fullconenat2 2>/dev/null
    if [ -d /tmp/fullconenat2/iptables-mod-fullconenat ]; then
        cp -r /tmp/fullconenat2/iptables-mod-fullconenat package/
        echo "  - fullconenat模块已添加（备用源）"
    else
        echo "  - 错误: fullconenat模块添加失败"
    fi
    rm -rf /tmp/fullconenat2 2>/dev/null
fi
rm -rf /tmp/fullconenat 2>/dev/null

# 6. 配置防火墙规则（刷机后自动启用Full Cone NAT）
echo "[6/6] 配置防火墙Full Cone NAT规则..."
mkdir -p package/base-files/files/etc
cat >> package/base-files/files/etc/firewall.user << 'FWEOF'

# Full Cone NAT 规则（刷机后自动生效）
# 改善P2P连接、游戏联机、视频会议等
iptables -t nat -A zone_wan_prerouting -j FULLCONENAT 2>/dev/null
iptables -t nat -A zone_wan_postrouting -j FULLCONENAT 2>/dev/null
FWEOF
echo "  - 防火墙Full Cone NAT规则已配置"

# 调试信息
echo ""
echo "  === 自定义包文件统计 ==="
TMPL_COUNT=$(find package/cups-zh-cn/files/usr/share/cups/templates/zh_CN/ -type f 2>/dev/null | wc -l)
DOC_COUNT=$(find package/cups-zh-cn/files/usr/share/cups/doc-root/zh_CN/ -type f 2>/dev/null | wc -l)
echo "  - CUPS Web模板: $TMPL_COUNT 个"
echo "  - CUPS帮助文档: $DOC_COUNT 个"
echo "  - fullconenat: $(test -d package/iptables-mod-fullconenat && echo '存在' || echo '不存在')"

echo "=========================================="
echo "构建信息:"
echo "  - OpenWrt版本: 24.10 Official Stable"
echo "  - 目标平台: x86_64"
echo "  - 打印: CUPS + Avahi + 中文(cups-zh-cn)"
echo "  - VPN: WireGuard + pbr"
echo "  - 网络: Tailscale/ACME/frp"
echo "  - 控制: timecontrol"
echo "  - NAT: Full Cone NAT + UPnP"
echo "=========================================="
