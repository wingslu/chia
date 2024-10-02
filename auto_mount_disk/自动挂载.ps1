
# 获取每个硬盘的最大分区卷标名和分区号（排除C盘）
$diskPartitions = Get-Partition | Where-Object { $_.Type -eq 'Basic' -and $_.DriveLetter -ne 'C' } | Group-Object DiskNumber | ForEach-Object {
    $maxSizePartition = $_.Group | Sort-Object -Property Size -Descending | Select-Object -First 1
    [PSCustomObject]@{
        DiskNumber = $_.Name
        PartitionNumber = $maxSizePartition.PartitionNumber
        Label = $null
        Size = $maxSizePartition.Size
    }
}

# 获取每个分区的卷标名
$diskPartitions | ForEach-Object {
    $diskNumber = $_.DiskNumber
    $partitionNumber = $_.PartitionNumber
    $volumes = Get-Partition | Where-Object { $_.DiskNumber -eq $diskNumber -and $_.PartitionNumber -eq $partitionNumber } | Get-Volume
    if ($volumes) {
        $maxVolume = $volumes | Sort-Object -Property Size -Descending | Select-Object -First 1
        $_.Label = $maxVolume.FileSystemLabel
    }
}

# 创建目标文件夹路径
$targetFolder = "C:\disk"

# 创建 diskpart 脚本文件
$scriptFilePath = "C:\diskpart_script.txt"
$commands = foreach ($entry in $diskPartitions) {
    $subFolder = Join-Path -Path $targetFolder -ChildPath $entry.Label
    if (-not (Test-Path -Path $subFolder)) {
        New-Item -Path $subFolder -ItemType Directory | Out-Null
    }

    "select disk $($entry.DiskNumber)",
    "select partition $($entry.PartitionNumber)",
    "assign mount=`"$subFolder`""
}
$commands | Out-File -FilePath $scriptFilePath -Encoding ASCII

# 在 diskpart 中执行脚本
$process = Start-Process -FilePath diskpart -ArgumentList "/s `"$scriptFilePath`"" -Verb RunAs -PassThru
$process.WaitForExit()

# 删除临时的 diskpart 脚本文件
# Remove-Item -Path $scriptFilePath -Force