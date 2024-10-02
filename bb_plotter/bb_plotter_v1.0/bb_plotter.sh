#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
set -e

############################################################################################################################################
############################################################################################################################################

# User Config
CONFIG_PLOT_MODEL='pp'    # input 'og' or 'pp' , default 'og'
CONFIG_PLOT_FARMER_KEY='a0e6bd3843db8eddf25df668dc538f046c81302ce33458e0fcc8dfdf5bde87f9579cee9e67c4fcabbf3fbfe5a8dd1955'    # 96 characters from a-z and 0-9
CONFIG_PLOT_POOL_KEY=''    # 96 characters from a-z and 0-9
CONFIG_PLOT_POOL_CONTRACT='xch14ft2c7w7he6qnh8nxnjleckh68g0rhmp0aldt4wl7wkl72pxyqaqw3dd2w'    # 62 characters from a-z and 0-9, start with xch
CONFIG_PLOT_COMPRESS_LEVEL='7'    # input '1-7' , default '7'
# 1: z1-88G-90112M"
# 2: z2-87G-89088M"
# 3: z3-85G-87040M"
# 4: z4-83G-84992M"
# 5: z5-82G-83968M"
# 6: z6-80G-81920M"
# 7: z7-79G-80896M"

# Disk Config
CONFIG_DISK_CACHE='/chia_plots_temp'
CONFIG_DISK_DATA='/chia_plots_disk'

############################################################################################################################################
############################################################################################################################################

# Tool Config
CONFIG_TOOL_INFO_NAME='bb_plotter'
CONFIG_TOOL_INFO_VER='v1.0'
CONFIG_TOOL_INFO_DESC='A chia plotter by bladebit_cuda'
CONFIG_TOOL_INFO_AUTHOR='Gee.Labs'
CONFIG_TOOL_INFO_WEBSITE='www.web3miner.io'
CONFIG_TOOL_INFO_EMAIL='mail.web3miner.io'

# Tool Path
if [ -L $0 ];then
	CONFIG_TOOL_DIR_ROOT=$(cd $(dirname $(readlink $0));pwd)
else
	CONFIG_TOOL_DIR_ROOT=$(cd $(dirname $0);pwd)
fi
CONFIG_TOOL_DIR_BIN="${CONFIG_TOOL_DIR_ROOT}/bin"
CONFIG_TOOL_DIR_LOG="${CONFIG_TOOL_DIR_ROOT}/logs"

# Tool Bin
CONFIG_TOOL_BIN_BLADEBIT="${CONFIG_TOOL_DIR_BIN}/bladebit_cuda"
CONFIG_TOOL_BIN_YQ="${CONFIG_TOOL_DIR_BIN}/yq_linux_amd64"

# Tool Logs
CONFIG_TOOL_LOG_BLADEBIT="${CONFIG_TOOL_DIR_LOG}/bladebit-$(date "+%Y%m%d-%H%M%S").log"
CONFIG_TOOL_LOG_PLOTTER="${CONFIG_TOOL_DIR_LOG}/plotter-$(date "+%Y%m%d-%H%M%S").log"


# Init user's config
CONFIG_DISK_CACHE=$(echo "$CONFIG_DISK_CACHE" | sed 's/\/$//')
CONFIG_DISK_DATA=$(echo "$CONFIG_DISK_DATA" | sed 's/\/$//')
if [[ "$CONFIG_PLOT_COMPRESS_LEVEL" = "1" ]]; then
	CONFIG_PLOT_SIZE=90112
elif [[ "$CONFIG_PLOT_COMPRESS_LEVEL" = "2" ]]; then
	CONFIG_PLOT_SIZE=89088
elif [[ "$CONFIG_PLOT_COMPRESS_LEVEL" = "3" ]]; then
	CONFIG_PLOT_SIZE=87040
elif [[ "$CONFIG_PLOT_COMPRESS_LEVEL" = "4" ]]; then
	CONFIG_PLOT_SIZE=84992
elif [[ "$CONFIG_PLOT_COMPRESS_LEVEL" = "5" ]]; then
	CONFIG_PLOT_SIZE=83968
elif [[ "$CONFIG_PLOT_COMPRESS_LEVEL" = "6" ]]; then
	CONFIG_PLOT_SIZE=81920
elif [[ "$CONFIG_PLOT_COMPRESS_LEVEL" = "7" ]]; then
	CONFIG_PLOT_SIZE=80896
fi

############################################################################################################################################
############################################################################################################################################

# Check user if root
if [ -z "$(cat /etc/os-release | grep "ubuntu")" ];then
	echo -e "\n\033[0;31m Please run with ubuntu system ! \033[0m\n"
	exit 1
fi

# Check user if root
if [ $UID -ne 0 ];then
	echo -e "\n\033[0;31m Please run with root ! \033[0m\n"
	exit 1
fi

# Check GPU if exist
if [ -z "$(nvidia-smi -L 2>/dev/null)" ];then
	echo -e "\n\033[0;31m The graphics card does not exist ! \033[0m\n"
	exit 1
fi

# Check RAM size
if [[ "$(free -m | grep "^Mem" | awk '{print $2}')" -lt "256000" ]];then
	echo -e "\n\033[0;31m The RAM size is less than 256g ! \033[0m\n"
	exit 1
fi

# Check tools if exist
if [[ ! -f $CONFIG_TOOL_BIN_BLADEBIT ]];then
	echo -e "\n\033[0;31m The bladebit bin does not exist ! \033[0m\n"
	exit 1
elif [[ ! -f $CONFIG_TOOL_BIN_YQ ]];then
	echo -e "\n\033[0;31m The yq bin does not exist ! \033[0m\n"
	exit 1
fi

# Check dependencies if exist
if ! type jq >/dev/null 2>&1; then
	echo -e "\n\033[0;31m The jq is not installed ! \033[0m\n"
	exit 1
elif ! type duf >/dev/null 2>&1; then
	echo -e "\n\033[0;31m The duf is not installed ! \033[0m\n"
	exit 1
elif ! type figlet >/dev/null 2>&1; then
	echo -e "\n\033[0;31m The figlet is not installed ! \033[0m\n"
	exit 1
fi

# Import main functions
. ${CONFIG_TOOL_DIR_ROOT}/include/main.sh

# Create logs dir
if [[ ! -d $CONFIG_TOOL_DIR_LOG ]]; then
	mkdir -p $CONFIG_TOOL_DIR_LOG
fi

# Log start
echo "============================================================================================" >> $CONFIG_TOOL_LOG_PLOTTER
echo "$(date "+%Y-%m-%d-%H:%M:%S") BB_PLOTTER START" >> $CONFIG_TOOL_LOG_PLOTTER

# Tool Init
read Terminal_Height Terminal_Width <<<"$(stty size)"

############################################################################################################################################
############################################################################################################################################

Check_User_Config
Show_Tool_Banner
Show_Tool_Info
Run_Bladebit_Cuda
Run_Monitor

exit
