#!/bin/bash
# 作者：地瓜真好吃 2025-06-15
# 功能：格式化未挂载的机械盘，格式化时分配一个数字序号，序号从1开始，
#       如果已挂载机械盘的挂载文件夹名称是数字则会跳过该序号避免冲突。
# 

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

#!/bin/bash
 
echo "！！！！！ ----- 准备执行硬盘格式化，请谨慎确认 ----- ！！！！！ (y/n)"
read answer
 
case $answer in
    [Yy]* ) echo "继续执行...";;
    [Nn]* ) echo "操作取消。"; exit;;
    * ) echo "请输入 y 或 n。";;
esac

sudo apt install btrfs-progs

# 获取已挂载的机械盘的数字标签
mounted_numbers=()
for mount_point in $(mount | grep "/dev/sd" | awk '{print $3}'); do
    if [[ $mount_point =~ ^/mnt/[0-9]+$ ]]; then
        number=$(basename "$mount_point")
        mounted_numbers+=($number)
    fi
done

# 获取所有机械盘
mechanical_disks=()
for disk in /dev/sd[a-z]*; do
    if [ -e "$disk" ]; then
        # 检查是否为机械盘
        if [[ $(cat /sys/block/$(basename $disk)/queue/rotational) -eq 1 ]]; then
            # 检查是否已挂载
            if ! mount | grep -q "^$disk"; then
                mechanical_disks+=("$disk")
            fi
        fi
    fi
done

# 如果没有找到未挂载的机械盘，退出
if [ ${#mechanical_disks[@]} -eq 0 ]; then
    echo "未找到未挂载的机械盘"
    exit 0
fi

# 从1开始分配序号
current_number=1
for disk in "${mechanical_disks[@]}"; do
    # 找到下一个可用的数字
    while [[ " ${mounted_numbers[@]} " =~ " $current_number " ]]; do
        ((current_number++))
    done
    
    echo "正在格式化 $disk 为 btrfs，标签为 $current_number"
    mkfs.btrfs -O zoned -m single -d single -f -L "$current_number" "$disk"
    
    if [ $? -eq 0 ]; then
        echo "格式化成功：$disk -> 标签 $current_number"
    else
        echo "格式化失败：$disk"
    fi
    
    ((current_number++))
done

rm -rf /mnt
echo "所有未挂载的机械盘格式化完成" 
