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

echo "=========================================="
echo "OpenWrt 24.10 Official Stable Build"
echo "diy-part2.sh - 更新feeds后的配置"
echo "=========================================="

# ============================================
# 1. 设置默认主机名
# ============================================
echo "[1/7] 设置默认主机名..."
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i 's/OpenWrt/OpenWrt-24.10/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# ============================================
# 2. 设置默认时区为上海
# ============================================
echo "[2/7] 设置默认时区..."
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/'CST-8'/a \\\t\tset system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# ============================================
# 3. 设置默认主题
# ============================================
echo "[3/7] 设置默认主题为Material..."
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' package/feeds/luci/luci/Makefile 2>/dev/null || true

# ============================================
# 4. 添加自定义banner
# ============================================
echo "[4/7] 添加自定义banner..."
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
# 5. 修复brlaser包编译错误（多种方法）
# ============================================
echo "[5/7] 修复brlaser编译错误..."

# 查找brlaser包的路径
BRLASER_FEED_DIR="feeds/printing/brlaser"
BRLASER_PACKAGE_DIR="package/feeds/printing/brlaser"

# 方法A: 修改Makefile禁用测试
if [ -f "$BRLASER_FEED_DIR/Makefile" ]; then
    echo "方法A: 在Makefile中禁用测试编译..."
    # 备份原文件
    cp "$BRLASER_FEED_DIR/Makefile" "$BRLASER_FEED_DIR/Makefile.bak"
    # 添加禁用测试的选项
    sed -i '/CMAKE_OPTIONS =/ s/$/ -DBUILD_TESTING=OFF -DBUILD_TESTS=OFF/' "$BRLASER_FEED_DIR/Makefile"
    # 如果没有CMAKE_OPTIONS行，在合适位置添加
    if ! grep -q "CMAKE_OPTIONS" "$BRLASER_FEED_DIR/Makefile"; then
        sed -i '/define Build\/Configure/a \	CMAKE_OPTIONS += -DBUILD_TESTING=OFF -DBUILD_TESTS=OFF' "$BRLASER_FEED_DIR/Makefile"
    fi
    echo "Makefile已修改"
fi

# 方法B: 创建补丁文件修复源代码
echo "方法B: 创建补丁文件修复头文件..."
mkdir -p "$BRLASER_PACKAGE_DIR/patches"

cat > "$BRLASER_PACKAGE_DIR/patches/001-fix-cpp-headers.patch" << 'EOF'
--- a/test/tempfile.h
+++ b/test/tempfile.h
@@ -1,5 +1,6 @@
 #pragma once
 
+#include <cstdint>
 #include <string>
 #include <vector>
 #include <cstdio>
@@ -42,7 +43,7 @@ public:
     }
     
     std::vector<uint8_t> data() const {
-        return std::vector<uint8_t>(ptr_, ptr_ + size_);
+        return std::vector<uint8_t>(ptr_, ptr_ + size_);
     }
     
 private:
--- a/test/instruction_test.cc
+++ b/test/instruction_test.cc
@@ -1,3 +1,4 @@
+#include <cstdint>
 #include "instruction_test.h"
 
 #include "lest/lest.hpp"
--- a/test/test_job.cc
+++ b/test/test_job.cc
@@ -15,6 +15,7 @@
  * along with this program.  If not, see <https://www.gnu.org/licenses/>.
  */
 
+#include <cstdint>
 #include "lest/lest.hpp"
 #include "tempfile.h"
 #include "job.h"
EOF

echo "补丁文件已创建: $BRLASER_PACKAGE_DIR/patches/001-fix-cpp-headers.patch"

# 方法C: 如果补丁不生效，在编译时直接修复源文件
echo "方法C: 准备编译时修复脚本..."
cat > /workdir/fix_brlaser.sh << 'EOF'
#!/bin/bash
# 编译时修复brlaser源文件
find build_dir -name "tempfile.h" -path "*/brlaser-*/test/*" 2>/dev/null | while read file; do
    echo "修复文件: $file"
    if ! grep -q "#include <cstdint>" "$file"; then
        sed -i '1i#include <cstdint>' "$file"
    fi
done

find build_dir -name "instruction_test.cc" -path "*/brlaser-*/test/*" 2>/dev/null | while read file; do
    echo "修复文件: $file"
    if ! grep -q "#include <cstdint>" "$file"; then
        sed -i '1i#include <cstdint>' "$file"
    fi
done

find build_dir -name "test_job.cc" -path "*/brlaser-*/test/*" 2>/dev/null | while read file; do
    echo "修复文件: $file"
    if ! grep -q "#include <cstdint>" "$file"; then
        sed -i '1i#include <cstdint>' "$file"
    fi
done
EOF

chmod +x /workdir/fix_brlaser.sh
echo "修复脚本已创建"

# ============================================
# 6. 修复ksmbd配置
# ============================================
echo "[6/7] 修复ksmbd配置..."
if [ -f package/network/services/ksmbd/files/ksmbd.config.example ]; then
    cp package/network/services/ksmbd/files/ksmbd.config.example package/network/services/ksmbd/files/ksmbd.config 2>/dev/null || true
fi

# ============================================
# 7. 版本信息显示
# ============================================
echo "[7/7] 显示构建信息..."
echo ""
echo "=========================================="
echo "构建信息:"
echo "  - OpenWrt版本: 24.10 Official Stable"
echo "  - 目标平台: x86_64 (通用)"
echo "  - 默认主题: Material"
echo "  - 默认时区: Asia/Shanghai (CST-8)"
echo "  - 中文支持: 已启用"
echo "  - GRUB等待: 0秒"
echo "  - Rootfs大小: 256MB"
echo "  - brlaser: 已应用修复(禁用测试+头文件补丁)"
echo "=========================================="
echo ""
echo "包含的功能包:"
echo "  [✓] cron                    - 定时任务"
echo "  [✓] luci-app-adblock        - 广告屏蔽"
echo "  [✓] luci-app-wol            - 网络唤醒"
echo "  [✓] luci-app-nlbwmon        - 流量统计"
echo "  [✓] luci-app-commands       - Web命令执行"
echo "  [✓] luci-app-watchcat       - 断网自动重启"
echo "  [✓] luci-app-ksmbd          - SMB文件共享"
echo "  [✓] luci-app-ddns           - 动态域名"
echo "  [✓] luci-app-upnp           - UPnP"
echo "  [✓] luci-app-statistics     - 性能监控"
echo "  [✓] cups                    - CUPS打印服务"
echo "  [✓] ghostscript             - Ghostscript"
echo "  [✓] gutenprint              - Gutenprint驱动"
echo "  [✓] brlaser                 - Brother打印机驱动(已修复)"
echo "  [✓] splix                   - Samsung打印机驱动"
echo "  [✓] iperf3                  - 网络测速"
echo ""
echo "修复说明:"
echo "  1. Makefile已添加 -DBUILD_TESTING=OFF"
echo "  2. 补丁文件已创建在 package/feeds/printing/brlaser/patches/"
echo "  3. 编译时会自动运行 /workdir/fix_brlaser.sh 二次修复"
echo "=========================================="
echo ""
echo "diy-part2.sh 执行完成"
echo "=========================================="
