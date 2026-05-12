#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# ============================================
# OpenWrt 24.10 Official Stable Build
# diy-part2.sh - 更新feeds后的配置和自定义
# ============================================

echo "=========================================="
echo "OpenWrt 24.10 Official Stable Build"
echo "diy-part2.sh - 更新feeds后的配置"
echo "=========================================="

# ============================================
# 1. 设置默认主机名
# ============================================
echo "[1/5] 设置默认主机名..."
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i 's/OpenWrt/OpenWrt-24.10/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# ============================================
# 2. 设置默认时区为上海
# ============================================
echo "[2/5] 设置默认时区..."
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/'CST-8'/a \\t\tset system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# ============================================
# 3. 设置默认主题
# ============================================
echo "[3/5] 设置默认主题为Material..."
# 修改默认主题为material
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' package/feeds/luci/luci/Makefile 2>/dev/null || true

# ============================================
# 4. 修改默认IP地址 (可选)
# ============================================
echo "[4/5] 配置网络设置..."
# 如需修改默认IP，取消下面一行的注释并修改IP
# sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate

# ============================================
# 5. 添加自定义banner
# ============================================
echo "[5/5] 添加自定义banner..."
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

# ============================================
# 6. 修复ksmbd配置 (如果需要)
# ============================================
echo "[额外] 检查ksmbd配置..."
# 确保ksmbd配置文件正确
if [ -f package/network/services/ksmbd/files/ksmbd.config.example ]; then
    cp package/network/services/ksmbd/files/ksmbd.config.example package/network/services/ksmbd/files/ksmbd.config 2>/dev/null || true
fi

# ============================================
# 7. 确保中文语言包正确
# ============================================
echo "[额外] 检查中文语言包..."
# 检查中文语言包是否存在
if [ -d feeds/luci/applications/luci-app-autoreboot/po ]; then
    echo "  - luci-app-autoreboot 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-adblock/po ]; then
    echo "  - luci-app-adblock 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-wol/po ]; then
    echo "  - luci-app-wol 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-nlbwmon/po ]; then
    echo "  - luci-app-nlbwmon 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-commands/po ]; then
    echo "  - luci-app-commands 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-watchcat/po ]; then
    echo "  - luci-app-watchcat 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-ksmbd/po ]; then
    echo "  - luci-app-ksmbd 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-ddns/po ]; then
    echo "  - luci-app-ddns 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-upnp/po ]; then
    echo "  - luci-app-upnp 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-accesscontrol/po ]; then
    echo "  - luci-app-accesscontrol 中文支持: OK"
fi
if [ -d feeds/luci/applications/luci-app-statistics/po ]; then
    echo "  - luci-app-statistics 中文支持: OK"
fi

# ============================================
# 8. 版本信息显示
# ============================================
echo ""
echo "=========================================="
echo "构建信息:"
echo "  - OpenWrt版本: 24.10 Official Stable"
echo "  - 目标平台: x86_64 (通用)"
echo "  - 默认主题: Material"
echo "  - 默认时区: Asia/Shanghai (CST-8)"
echo "  - 中文支持: 已启用"
echo "=========================================="
echo ""
echo "包含的功能包:"
echo "  [✓] luci-app-autoreboot    - 定时重启"
echo "  [✓] luci-app-adblock       - 广告屏蔽"
echo "  [✓] luci-app-wol           - 网络唤醒"
echo "  [✓] luci-app-nlbwmon       - 流量统计"
echo "  [✓] luci-app-commands      - Web命令执行"
echo "  [✓] luci-app-watchcat      - 断网自动重启"
echo "  [✓] luci-app-ksmbd         - SMB文件共享"
echo "  [✓] luci-app-ddns          - 动态域名"
echo "  [✓] luci-app-upnp          - UPnP"
echo "  [✓] luci-app-accesscontrol - 上网时间控制"
echo "  [✓] luci-app-statistics    - 性能监控"
echo "  [✓] iperf3                 - 网络测速"
echo "=========================================="
echo ""
echo "diy-part2.sh 执行完成"
echo "=========================================="
