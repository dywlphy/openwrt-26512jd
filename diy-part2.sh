#!/bin/bash

echo "=========================================="
echo "OpenWrt 24.10 Official Stable Build"
echo "diy-part2.sh - 更新feeds后的配置"
echo "=========================================="

# 1. 设置默认主机名
echo "[1/5] 设置默认主机名..."
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate 2>/dev/null || true
sed -i 's/OpenWrt/OpenWrt-24.10/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# 2. 设置默认时区为上海
echo "[2/5] 设置默认时区..."
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/'CST-8'/a \\\t\tset system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# 3. 设置默认主题
echo "[3/5] 设置默认主题为Material..."
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-material/g' package/feeds/luci/luci/Makefile 2>/dev/null || true

# 4. 添加自定义banner
echo "[4/5] 添加自定义banner..."
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

# 5. 修复brlaser
echo "[5/5] 修复brlaser编译错误..."

# 修改Makefile禁用测试
if [ -f "feeds/printing/brlaser/Makefile" ]; then
    sed -i 's/-DBUILD_TESTING=ON/-DBUILD_TESTING=OFF/g' feeds/printing/brlaser/Makefile
    sed -i '/CMAKE_OPTIONS/ s/$/ -DBUILD_TESTING=OFF -DBUILD_TESTS=OFF/' feeds/printing/brlaser/Makefile
fi

# 创建直接修复脚本
cat > /workdir/fix_brlaser.sh << 'EOF'
#!/bin/bash
find openwrt/build_dir -type f -path "*/brlaser-*/test/tempfile.h" 2>/dev/null | while read f; do
    grep -q "#include <cstdint>" "$f" || sed -i '1i#include <cstdint>' "$f"
done
find openwrt/build_dir -type f -path "*/brlaser-*/test/instruction_test.cc" 2>/dev/null | while read f; do
    grep -q "#include <cstdint>" "$f" || sed -i '1i#include <cstdint>' "$f"
done
find openwrt/build_dir -type f -path "*/brlaser-*/test/test_job.cc" 2>/dev/null | while read f; do
    grep -q "#include <cstdint>" "$f" || sed -i '14i#include <cstdint>' "$f"
done
EOF

chmod +x /workdir/fix_brlaser.sh

echo "=========================================="
echo "构建信息:"
echo "  - OpenWrt版本: 24.10 Official Stable"
echo "  - 目标平台: x86_64"
echo "  - brlaser: 已修复"
echo "=========================================="
