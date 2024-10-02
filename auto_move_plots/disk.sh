
#!/bin/bash

diskPartitions=()
while read -r line; do
    diskNumber=$(echo "$line" | awk '{print $1}')
    partitionNumber=$(echo "$line" | awk '{print $2}')
    size=$(echo "$line" | awk '{print $3}')
    label=""

    # 获取每个分区的卷标名
    volumes=$(lsblk -no NAME,FSTYPE,MOUNTPOINT | grep "^$diskNumber $partitionNumber " | awk '{print $2}')
    if [ -n "$volumes" ]; then
        label=$(echo "$volumes" | tr '\n' ' ')
    fi

    diskPartitions+=("$diskNumber $partitionNumber $label $size")
done < <(lsblk -ln -o NAME,SIZE | grep -v "C " | grep "disk" | awk '{print $1}')

# 创建目标文件夹路径
targetFolder="/mnt/disk"

# 创建挂载点文件夹
for entry in "${diskPartitions[@]}"; do
    diskNumber=$(echo "$entry" | awk '{print $1}')
    partitionNumber=$(echo "$entry" | awk '{print $2}')
    label=$(echo "$entry" | awk '{print $3}')
    size=$(echo "$entry" | awk '{print $4}')

    subFolder="$targetFolder/$label"
    mkdir -p "$subFolder"

    # 挂载分区到目标文件夹
    mount -t nfs - 3g "/dev/$diskNumber$partitionNumber" "$subFolder" -o norecover,big_writes
done