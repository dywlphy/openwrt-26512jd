#!/bin/bash

# ==========================================
# feeds 配置：官方默认源 + helloworld
# ==========================================

# 在官方 feeds.conf.default 末尾追加 helloworld 源
echo "" >> feeds.conf.default
echo "src-git helloworld https://github.com/fw876/helloworld" >> feeds.conf.default

echo "✅ 已添加 helloworld 源"
cat feeds.conf.default
