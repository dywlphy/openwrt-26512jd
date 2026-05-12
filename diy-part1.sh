#!/bin/bash
echo "===== 配置 feeds 源  ====="
> feeds.conf
# 官方源
echo "src-git packages https://github.com/openwrt/packages.git;openwrt-24.10" >> feeds.conf
echo "src-git luci https://github.com/openwrt/luci.git;openwrt-24.10" >> feeds.conf

