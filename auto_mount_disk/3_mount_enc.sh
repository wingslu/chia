#!/bin/bash
# 作者：地瓜真好吃 2025-06-15
# 功能：自动挂载机械盘，挂载时会检查机械盘的标签，如果标签是数字则会挂载到/mnt/数字目录下。
# 注意：专为加密盘btrfs格式设计，其他有分区的机械盘不适用。
# 
# 使用方法：
#   1. 将脚本保存为 automount.sh
#   2. 赋予执行权限：chmod +x automount.sh
#   3. 运行脚本：./automount.sh
# 
# 设置挂载根目录，默认为/mnt
MOUNT_ROOT=${1:-"/mnt"}

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 确保挂载根目录存在
if [ ! -d "$MOUNT_ROOT" ]; then
    echo "创建挂载根目录: $MOUNT_ROOT"
    sudo mkdir -p "$MOUNT_ROOT"
fi

# 获取所有机械盘设备
for disk in /dev/sd[a-z]*; do
    if [ -e "$disk" ]; then
        # 检查磁盘是否已经挂载
        if ! mount | grep -q "$disk"; then
            # 尝试获取磁盘标签中的数字
            label=$(sudo btrfs inspect-internal dump-super "$disk" 2>/dev/null | grep label)
            if [ ! -z "$label" ]; then
                # 提取标签中的数字
                number=$(echo "$label" | awk '{print $2}')
                if [ ! -z "$number" ]; then
                    mount_point="${MOUNT_ROOT}/${number}"
                    echo "准备挂载 $disk 到 $mount_point"
                    
                    # 创建挂载点
                    sudo mkdir -p "$mount_point"
                    
                    # 尝试挂载
                    if sudo mount "$disk" "$mount_point"; then
                        echo "成功挂载 $disk 到 $mount_point"
                    else
                        echo "挂载 $disk 失败"
                        sudo rmdir "$mount_point"
                    fi
                else
                    echo "在 $disk 上未找到有效的数字标签，跳过挂载"
                fi
            else
                echo "在 $disk 上未找到标签信息，跳过挂载"
            fi
        else
            echo "$disk 已经挂载，跳过"
        fi
    fi
done

echo "挂载操作完成" 



