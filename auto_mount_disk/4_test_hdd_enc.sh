#!/bin/bash
# 作者：？
# 功能：？
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

rm -f /home/sm/dgar/test_hdd.log
lsblk -o NAME,MODEL,SERIAL >> /home/sm/dgar/test_hdd.log 2>&1

# 获取所有机械盘设备
{
for disk in /dev/sd[a-z]*; do
    if [ -e "$disk" ]; then
        # 检查磁盘是否已经挂载
        if mount | grep -q "$disk"; then
            # 尝试获取磁盘标签中的数字
            label=$(sudo btrfs inspect-internal dump-super "$disk" 2>/dev/null | grep label)
            if [ ! -z "$label" ]; then
                # 提取标签中的数字
                number=$(echo "$label" | awk '{print $2}')
                if [ ! -z "$number" ]; then
                    mount_point="${MOUNT_ROOT}/${number}"
                    echo "正在测试 $disk - $mount_point"
                    
                    # 创建挂载点
                    #sudo mkdir -p "$mount_point"
                    
                    # 尝试挂载
                    #if sudo mount "$disk" "$mount_point"; then
                    #    echo "成功挂载 $disk 到 $mount_point"
                    #else
                    #    echo "挂载 $disk 失败"
                    #    sudo rmdir "$mount_point"
                    #fi


                    mkdir -p $mount_point/test_hdd
                    #echo "mnt/1（$disk） 写入测试" >> /home/sm/dgar/test_hdd.log 2>&1
                    echo "$disk  ===  $mount_point  ===  写入测试"  ===  $(dd if=/dev/zero of=$mount_point/test_hdd/test_w bs=1G count=1 oflag=direct 2>&1 | grep "copied") >> /home/sm/dgar/test_hdd.log 2>&1 &

                    ((count++))
                else
                    echo "在 $disk 上未找到有效的数字标签，跳过测试"
                fi
            else
                echo "在 $disk 上未找到标签信息，跳过测试"
            fi
        else
            echo "$disk 未挂载，跳过"
        fi
    fi
done
};wait


cat /home/sm/dgar/test_hdd.log

echo "======测试完成完成（共测试 $count 个硬盘）======" 



