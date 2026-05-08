#!/bin/bash
# ==========================================
# diy-part1.sh - 配置 Feed 源（基础版，无 printing 源）
# ==========================================

echo "===== 配置 feeds ====="

# 创建 feeds.conf.default（不包含 printing 源）
cat > feeds.conf.default <<'EOF'
src-git kenzo https://github.com/kenzok8/openwrt-packages.git
src-git small https://github.com/kenzok8/small.git
src-git smpackage https://github.com/kenzok8/small-package
src-git helloworld https://github.com/fw876/helloworld
src-git immortalwrt https://github.com/immortalwrt/packages.git;openwrt-24.10
EOF

echo "  已创建 feeds.conf.default"
echo "  1. kenzo       - 常用软件包"
echo "  2. small       - 科学上网相关"
echo "  3. smpackage   - 小型软件包集合"
echo "  4. helloworld  - SSR-Plus 源"
echo "  5. immortalwrt - ImmortalWrt 软件包"
echo ""
echo "注意：基础版本不包含 printing 源"
