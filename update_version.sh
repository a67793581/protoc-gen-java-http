#!/bin/bash

# 设置错误立即退出
set -e

# 获取当前版本号
current_version=$(cat version)
echo "当前版本: $current_version"

# 更新版本号（将最后一个数字加1）
new_version=$(echo $current_version | awk -F. '{$NF = $NF + 1;} 1' OFS=.)
echo "新版本: $new_version"

# 更新版本文件
echo $new_version > version

# 提交到git
git add -A
git commit -m "chore: bump version to $new_version"

# 创建新标签
git tag $new_version

# 推送更改和标签到远程仓库
git push 
git push origin $new_version

echo "版本更新完成！"