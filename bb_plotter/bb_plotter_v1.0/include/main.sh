#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

Check_Plot_Config(){
	# Check plot model
	if [ "$CONFIG_PLOT_MODEL" != "og" ] && [ "$CONFIG_PLOT_MODEL" != "pp" ]; then
		echo -e "\033[0;31m  CONFIG ERROR : 'CONFIG_PLOT_MODEL' parameter setting error in configuration file !\033[0m"
		exit 1
	fi

	# Check plot farmer_key
	if [[ -n "$(echo $CONFIG_PLOT_FARMER_KEY | sed 's/[a-z0-9]//g')" ]] || [[ "${#CONFIG_PLOT_FARMER_KEY}" != "96" ]]; then
		echo -e "\033[0;31m  CONFIG ERROR : 'CONFIG_PLOT_FARMER_KEY' parameter setting error in configuration file !\033[0m"
		exit 1
	fi

	# Check plot pool_key && pool_contract
	if [ "$CONFIG_PLOT_MODEL" = "og" ]; then
		if [[ -n "$(echo $CONFIG_PLOT_POOL_KEY | sed 's/[a-z0-9]//g')" ]] || [[ "${#CONFIG_PLOT_POOL_KEY}" != "96" ]]; then
			echo -e "\033[0;31m  CONFIG ERROR : The pool_key consists of 96 characters from a-z and 0-9\033[0m"
			exit 1
		fi
	elif [ "$CONFIG_PLOT_MODEL" = "pp" ]; then
		if [[ -n "$(echo $CONFIG_PLOT_POOL_CONTRACT | sed 's/[a-z0-9]//g')" ]] || [[ "${#CONFIG_PLOT_POOL_CONTRACT}" != "62" ]] || [[ -z "$(echo $CONFIG_PLOT_POOL_CONTRACT | grep "^xch")" ]]; then
			echo -e "\033[0;31m  CONFIG ERROR : The pool_contract consists of 62 characters from a-z and 0-9 and start with 'xch'\033[0m"
			exit 1
		fi
	fi
	
	# Check plot compress level (1-7)
	if [[ -z "$(seq 1 7 | grep -w $CONFIG_PLOT_COMPRESS_LEVEL)" ]]; then
		echo -e "\033[0;31m  CONFIG ERROR : please input 1-7\033[0m"
		exit 1
	fi
}

Check_Disk_Config(){
	# Check cache disk
	if [[ ! -d $CONFIG_DISK_CACHE ]]; then
		echo -e "\033[0;31m  Warning : the cache disk dir does not exist !\033[0m"
		exit 1
	elif [[ -z "$(df -h | grep -w "${CONFIG_DISK_CACHE}$")" ]]; then
		echo -e "\033[0;31m  Warning : the cache disk does not mount !\033[0m"
		exit 1
	elif [[ "$(df -m | grep -w "$CONFIG_DISK_CACHE" | awk '{print $4}')" -lt "1048576" ]]; then
		echo -e "\033[0;31m  Warning : the cache disk free size is less than 1T !\033[0m"
		exit 1
	fi

	# Check data disk
	if [[ ! -d $CONFIG_DISK_DATA ]]; then
		echo -e "\033[0;31m  Warning : the plot data dir does not exist !\033[0m"
		exit 1
	elif [[ -z "$(df -h | grep "${CONFIG_DISK_DATA}/")" ]]; then
		echo -e "\033[0;31m  Warning : the plot data does not mount !\033[0m"
		exit 1
	fi
}

Check_User_Config(){
	Check_Plot_Config
	Check_Disk_Config
}

Show_Tool_Banner(){
	local _Desc_Info="$CONFIG_TOOL_INFO_NAME $CONFIG_TOOL_INFO_VER"
	local _Author_Info="Powered by $CONFIG_TOOL_INFO_AUTHOR ($CONFIG_TOOL_INFO_WEBSITE)"
	printf "%0.s=" $(seq 1 $Terminal_Width) && echo
	figlet -w $Terminal_Width -c bb-plotter && echo
	printf "%*s\n" $(((${#_Desc_Info}+$Terminal_Width)/2)) "$_Desc_Info"
	printf "%*s\n" $(((${#_Author_Info}+$Terminal_Width)/2)) "$_Author_Info"
	printf "%0.s=" $(seq 1 $Terminal_Width) && echo
}

Check_CPU_Info(){
	
	# CPU Model
	CPU_Model=`lscpu | grep "^Model name:" | awk -F ':' '{print $2}' | sed 's/^\s*//' | sed 's/ /-/g'`

	# CPU Sockets
	CPU_Sockets=`lscpu | grep "^Socket(s):" | awk -F ':' '{print $2}' | sed 's/^\s*//'`

	# CPU Cores
	CPU_Cores=`lscpu | grep "^Core(s) per socket:" | awk -F ':' '{print $2}' | sed 's/^\s*//'`

	# CPU Threads
	CPU_Threads=`lscpu | grep "^CPU(s):" | awk -F ':' '{print $2}' | sed 's/^\s*//'`

	# CPU Usage
	CPU_Usage=`top -bn1 | grep "^\%Cpu(s):" | sed 's/%Cpu(s)://' | sed 's/^\s*//' | awk '{print $1}'`
}

Check_GPU_Info(){
	GPU_UUID_ARR=($(nvidia-smi -L 2>/dev/null | sed 's/^.*.UUID: //;s/)//' | xargs))
}

Check_RAM_Info(){
	read RAM_Total RAM_Used RAM_Free RAM_Shared RAM_Cache RAM_Avail <<< "$(free -m | grep "^Mem" | awk '{print $2,$3,$4,$5,$6,$7}')"
	read RAM_Total_H RAM_Used_H RAM_Free_H RAM_Shared_H RAM_Cache_H RAM_Avail_H <<< "$(free -h | grep "^Mem" | awk '{print $2,$3,$4,$5,$6,$7}')"
	RAM_Usage="$(echo "scale=2;($RAM_Total-$RAM_Free)/$RAM_Total*100" | bc)%"
}

Check_Bladebit_Info(){
	Bladebit_Ver=$($CONFIG_TOOL_BIN_BLADEBIT --version)
}

Check_Data_Disk(){
	unset CONFIG_DISK_DATA_ARR
	unset CONFIG_DISK_FREE_ARR
	unset CONFIG_DISK_DATA_MV

	CONFIG_DISK_DATA_ARR=($(df -h | grep "$CONFIG_DISK_DATA" | awk '{print $NF}' | xargs))
	for i in ${CONFIG_DISK_DATA_ARR[*]}; do
		if [[ -z "$(ps -ef | grep -v grep | grep "mv" | grep "$i")" ]] && [[ "$(df -m | grep "${i}$" | awk '{print $4}')" -gt "$CONFIG_PLOT_SIZE" ]]; then
			CONFIG_DISK_FREE_ARR[${#CONFIG_DISK_FREE_ARR[@]}]="$(echo "$i:$(ls -lh ${i}/*.plot 2>/dev/null | wc -l)")"
		fi
	done
	CONFIG_DISK_DATA_MV=$(echo "${CONFIG_DISK_FREE_ARR[*]}" | xargs | sed 's/ /\n/g' | sort -t : -k 2,2n | sed -n '1p' | awk -F':' '{print $1}')
}

Check_Cache_Disk(){
	if [[ -z "$CONFIG_DISK_CACHE" ]]; then
		echo -e "\033[0;33m  ERROR\033[0m"
		exit 1
	fi
	read Disk_Cache_Total Disk_Cache_Used Disk_Cache_Avail <<< "$(df -m $CONFIG_DISK_CACHE | grep "$CONFIG_DISK_CACHE" | awk '{print $2,$3,$4}')"
	read Disk_Cache_Total_H Disk_Cache_Used_H Disk_Cache_Avail_H <<< "$(df -h $CONFIG_DISK_CACHE | grep "$CONFIG_DISK_CACHE" | awk '{print $2,$3,$4}')"
	Disk_Cache_Usage=$(df -h $CONFIG_DISK_CACHE | grep "$CONFIG_DISK_CACHE" | awk '{print $5}')
}

Show_Tool_Info(){

	Check_CPU_Info
	Check_GPU_Info
	Check_RAM_Info
	Check_Bladebit_Info
	Check_Data_Disk
	Check_Cache_Disk

	### Plof Info ###
	echo -e "\n     [Plot Info]"

	# Show plot model
	echo "         Model : $CONFIG_PLOT_MODEL"

	# Show plot level
	echo "    Plot_Level : $CONFIG_PLOT_COMPRESS_LEVEL"

	# Show plot farmer_key
	echo "    Farmer_Key : $CONFIG_PLOT_FARMER_KEY"

	# Show plot pool_key or pool_contract
	if [[ "$CONFIG_PLOT_MODEL" = "og" ]]; then
		echo "      Pool_Key : $CONFIG_PLOT_POOL_KEY"
	else
		echo " Pool_Contract : $CONFIG_PLOT_POOL_CONTRACT"
	fi

	# Show cache disk
	echo "    Cache Disk : $CONFIG_DISK_CACHE"

	# Show data disk
	echo "     Data Disk : $CONFIG_DISK_DATA"

	### System Info ###
	echo -e "\n      [Sys Info]"

	# Show system time
	echo "          Time : $(date "+%Y-%m-%d-%H:%M:%S")"

	# Show CPU info
	echo "           CPU : ${CPU_Model} * ${CPU_Cores} cores * ${CPU_Sockets}"

	# Show RAM info
	echo "           RAM : ${RAM_Used_H} / ${RAM_Total_H} ( $RAM_Usage usage )"

	# Show GPU info
	for i in ${!GPU_UUID_ARR[*]}; do
		echo "           GPU : [$(expr $i + 1)/${#GPU_UUID_ARR[*]}] ${GPU_UUID_ARR[$i]} ( $(nvidia-smi -q -i ${GPU_UUID_ARR[*]} 2>/dev/null | grep "Product Name" | awk -F':' '{print $2}' | sed 's/^ //;s/ /-/g') )"
	done

	# Show bladebit info
	echo "      Bladebit : bladebit_cuda ${Bladebit_Ver}"
	
	# Show log info
	echo "           Log : Plotter => ${CONFIG_TOOL_LOG_PLOTTER}"
	echo "           Log : Bladebit => ${CONFIG_TOOL_LOG_PLOTTER}"

	# Show cache disk info
	echo "    Cache Disk : ${Disk_Cache_Used_H} / ${Disk_Cache_Total_H} ( $Disk_Cache_Usage usage)"

	# Show data disk info
	for i in ${!CONFIG_DISK_DATA_ARR[*]}; do
		echo "     Data Disk : [$(expr $i + 1)/${#CONFIG_DISK_DATA_ARR[*]}]  $(df -h | grep "${CONFIG_DISK_DATA_ARR[$i]}$" | awk '{print $NF,"  "$3"/"$4"/"$2,"  "$5}')"
	done

	echo &&	printf "%0.s-" $(seq 1 $Terminal_Width) && echo

	# Write into plotter.log
	echo "$(date "+%Y-%m-%d-%H:%M:%S") Plot_Model=$CONFIG_PLOT_MODEL" >> $CONFIG_TOOL_LOG_PLOTTER
	echo "$(date "+%Y-%m-%d-%H:%M:%S") Plot_Farmer_Key=$CONFIG_PLOT_FARMER_KEY" >> $CONFIG_TOOL_LOG_PLOTTER
	if [[ "$CONFIG_PLOT_MODEL" = "og" ]]; then
		echo "$(date "+%Y-%m-%d-%H:%M:%S") Plot_Pool_Key=$CONFIG_PLOT_POOL_KEY" >> $CONFIG_TOOL_LOG_PLOTTER
	else
		echo "$(date "+%Y-%m-%d-%H:%M:%S") Plot_Pool_Contract=$CONFIG_PLOT_POOL_CONTRACT" >> $CONFIG_TOOL_LOG_PLOTTER
	fi
	echo "$(date "+%Y-%m-%d-%H:%M:%S") Plot_Compress_level=$CONFIG_PLOT_COMPRESS_LEVEL" >> $CONFIG_TOOL_LOG_PLOTTER
	echo "$(date "+%Y-%m-%d-%H:%M:%S") Cache_Disk=$CONFIG_DISK_CACHE Cache_Disk_Used=$Disk_Cache_Used_H Cache_Disk_Total=$Disk_Cache_Total_H" >> $CONFIG_TOOL_LOG_PLOTTER
	for i in ${!CONFIG_DISK_DATA_ARR[*]}; do
		echo "$(date "+%Y-%m-%d-%H:%M:%S") Data_Disk_ID=$(expr $i + 1)/${#CONFIG_DISK_DATA_ARR[*]} Data_Disk=${CONFIG_DISK_DATA_ARR[$i]} Data_Disk_Used=$(df -h | grep "${CONFIG_DISK_DATA_ARR[$i]}$" | awk '{print $3"/"$4"/"$2}')" >> $CONFIG_TOOL_LOG_PLOTTER
	done
	echo "$(date "+%Y-%m-%d-%H:%M:%S") CPU_Model=${CPU_Model} CPU_Cores=${CPU_Cores} CPU_Num=${CPU_Sockets}" >> $CONFIG_TOOL_LOG_PLOTTER
	echo "$(date "+%Y-%m-%d-%H:%M:%S") RAM_Total=$RAM_Total_H RAM_Used=$RAM_Used_H" >> $CONFIG_TOOL_LOG_PLOTTER
	for i in ${!GPU_UUID_ARR[*]}; do
		echo "$(date "+%Y-%m-%d-%H:%M:%S") GPU_ID=$(expr $i + 1)/${#GPU_UUID_ARR[*]} GPU_UUID=${GPU_UUID_ARR[$i]} GPU_Type=$(nvidia-smi -q -i ${GPU_UUID_ARR[*]} 2>/dev/null | grep "Product Name" | awk -F':' '{print $2}' | sed 's/^ //;s/ /-/g')" >> $CONFIG_TOOL_LOG_PLOTTER
	done
	echo "$(date "+%Y-%m-%d-%H:%M:%S") Bladebit_Ver=$Bladebit_Ver" >> $CONFIG_TOOL_LOG_PLOTTER

}

Check_Bladebit_Process(){
	Bladebit_Process_Id="$(ps -ef | grep -v grep | grep "bladebit_cuda" | awk '{print $2}')"
}

Run_Bladebit_Cuda(){
	
	# Check cache disk free
	# if [[ "$(df -m | grep /chia_plots_temp | awk '{print $4}')" -lt "102400" ]]; then
	# 	#statements
	# fi

	# Check bladebit running
	Check_Bladebit_Process
	if [[ -n "$Bladebit_Process_Id" ]]; then
		echo "ERROR : bladebit_cuda is running !"
		exit 1
	fi

	# Run bladebit_cuda
	if [[ "$CONFIG_PLOT_MODEL" = "og" ]]; then
		(bladebit_cuda -n 0 -f $CONFIG_PLOT_FARMER_KEY -p $CONFIG_PLOT_POOL_KEY --compress $CONFIG_PLOT_COMPRESS_LEVEL cudaplot $CONFIG_DISK_CACHE >> $CONFIG_TOOL_LOG_BLADEBIT 2>&1 &)
	else
		(bladebit_cuda -n 0 -f $CONFIG_PLOT_FARMER_KEY -c $CONFIG_PLOT_POOL_CONTRACT --compress $CONFIG_PLOT_COMPRESS_LEVEL cudaplot $CONFIG_DISK_CACHE >> $CONFIG_TOOL_LOG_BLADEBIT 2>&1 &)
	fi
	echo "$(date "+%Y-%m-%d-%H:%M:%S") ----------------------------------------------------------------------" >> $CONFIG_TOOL_LOG_PLOTTER
	echo "$(date "+%Y-%m-%d-%H:%M:%S") Bladebit_Cuda : Start $CONFIG_PLOT_MODEL" >> $CONFIG_TOOL_LOG_PLOTTER
}

Run_Monitor(){
	if [[ ! -f $CONFIG_TOOL_LOG_BLADEBIT ]]; then
		echo -e "\n\033[0;31m $CONFIG_TOOL_LOG_BLADEBIT does not exist ! \033[0m\n"
		exit 1
	fi

	# Check Allocating Buffers
	while true; do
		if [[ -n "$(cat $CONFIG_TOOL_LOG_BLADEBIT | grep "^Allocating buffers")" ]]; then
			echo "$(date "+%Y-%m-%d-%H:%M:%S")  Bladebit_Cuda : Allocating buffers" | tee -a $CONFIG_TOOL_LOG_PLOTTER
			break 1
		fi
	done

	Plot_Num=1
	while true; do

		# Get Task_ID and Plot_ID
		while true; do
			Plot_Id=$(cat $CONFIG_TOOL_LOG_BLADEBIT | grep "^Generating plot ${Plot_Num}:" | awk '{print $NF}')
			if [[ -n "$Plot_Id" ]]; then
				echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot $Plot_Num : Plot_Id=$Plot_Id" | tee -a $CONFIG_TOOL_LOG_PLOTTER
				break 1
			fi
		done

		# Get Plot_Path
		while true; do
			Plot_Path=$(cat $CONFIG_TOOL_LOG_BLADEBIT | grep "^Generating plot ${Plot_Num}:" -A74 | grep "^Plot temporary file:" | head -n +1 | awk '{print $NF}' | sed 's/.tmp//')
			if [[ -n "$Plot_Path" ]]; then
				echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot $Plot_Num : Plot_Path=$Plot_Path" | tee -a $CONFIG_TOOL_LOG_PLOTTER
				break 1
			fi
		done

		# Get Plot Completed Phase 1 Time
		while true; do
			Plot_Phase_1_Time="$(cat $CONFIG_TOOL_LOG_BLADEBIT | grep "^Generating plot ${Plot_Num}:" -A74 | grep "^Completed Phase 1 in" | head -n +1 | awk -F'in ' '{print $2}')"
			if [[ -n "$Plot_Phase_1_Time" ]]; then
				echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot $Plot_Num : Phase_1_time => $Plot_Phase_1_Time" | tee -a $CONFIG_TOOL_LOG_PLOTTER
				break 1
			fi
		done

		# Get Plot Completed Phase 2 Time
		while true; do
			Plot_Phase_2_Time="$(cat $CONFIG_TOOL_LOG_BLADEBIT | grep "^Generating plot ${Plot_Num}:" -A74 | grep "^Completed Phase 2 in" | head -n +1 | awk -F'in ' '{print $2}')"
			if [[ -n "$Plot_Phase_2_Time" ]]; then
				echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot $Plot_Num : Phase_2_time => $Plot_Phase_2_Time" | tee -a $CONFIG_TOOL_LOG_PLOTTER
				break 1
			fi
		done

		# Get Plot Completed Phase 3 Time
		while true; do
			Plot_Phase_3_Time="$(cat $CONFIG_TOOL_LOG_BLADEBIT | grep "^Generating plot ${Plot_Num}:" -A74 | grep "^Completed Phase 3 in" | head -n +1 | awk -F'in ' '{print $2}')"
			if [[ -n "$Plot_Phase_3_Time" ]]; then
				echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot $Plot_Num : Phase_3_time => $Plot_Phase_3_Time" | tee -a $CONFIG_TOOL_LOG_PLOTTER
				break 1
			fi
		done

		# Get Plot Completed Time
		while true; do
			Plot_Completed_Time="$(cat $CONFIG_TOOL_LOG_BLADEBIT | grep "^Generating plot ${Plot_Num}:" -A74 | grep "^Completed Plot 1" | head -n +1 | awk -F'in ' '{print $2}')"
			if [[ -n "$Plot_Completed_Time" ]]; then
				echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot ${Plot_Num} : Completed Plot => $Plot_Completed_Time" | tee -a $CONFIG_TOOL_LOG_PLOTTER
				break 1
			fi
		done

		# Get Plot Written Time
		while true; do
			Plot_Written_Time="$(cat $CONFIG_TOOL_LOG_BLADEBIT | grep "^Generating plot ${Plot_Num}:" -A75 | grep "^Completed writing plot" | head -n +1 | awk -F'in ' '{print $2}')"
			if [[ -n "$Plot_Written_Time" ]]; then
				echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot ${Plot_Num} : Written Plot => $Plot_Written_Time" | tee -a $CONFIG_TOOL_LOG_PLOTTER
				break 1
			fi
		done

		# Check Plot Finished
		while true; do
			if [[ -n "$(cat $CONFIG_TOOL_LOG_BLADEBIT | grep "^Generating plot ${Plot_Num}:" -A80 | grep "^Final plot table sizes")" ]]; then
				echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot ${Plot_Num} : Plot Finished" | tee -a $CONFIG_TOOL_LOG_PLOTTER
				break 1
			fi
		done

		# Run mover
		Check_Data_Disk
		echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot ${Plot_Num} : Mover Start => ${CONFIG_DISK_DATA_MV}" | tee -a $CONFIG_TOOL_LOG_PLOTTER
		(echo $(mv ${Plot_Path} ${CONFIG_DISK_DATA_MV} && echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot ${Plot_Num} : Mover End" | tee -a $CONFIG_TOOL_LOG_PLOTTER && echo "plot_id=$Plot_Id plot_model=$CONFIG_PLOT_MODEL plot_level=$CONFIG_PLOT_COMPRESS_LEVEL plot_farmer_key=$CONFIG_PLOT_FARMER_KEY" >> ${CONFIG_DISK_DATA_MV}/plots-info.log) &)

		# Check_Data_Disk
		# while true; do
		# 	for Disk_Data_Item in ${CONFIG_DISK_DATA_ARR[*]}; do
		# 		if [[ -z "$(ps -ef | grep mv | grep "$Disk_Data_Item")" ]] && [[ "$(df -m | grep "${Disk_Data_Item}$" | awk '{print $4}')" -gt "$CONFIG_DISK_DATA_HOLD_SIZE" ]]; then
		# 			echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot ${Plot_Num} : Mover Start => ${Disk_Data_Item}" | tee -a $CONFIG_TOOL_LOG_PLOTTER
		# 			(echo $(mv ${Plot_Path} ${CONFIG_DISK_DATA_MV} && echo "$(date "+%Y-%m-%d-%H:%M:%S")  Plot ${Plot_Num} : Mover End" | tee -a $CONFIG_TOOL_LOG_PLOTTER) &)
		# 			break 2
		# 		fi
		# 	done
		# done

		sleep 1
		let Plot_Num++
	done
}

trap 'onCtrlC' INT
onCtrlC () {
	# Kill Bladebit_cuda
	Check_Bladebit_Process
	if [[ -n "$Bladebit_Process_Id" ]]; then
		echo "$(date "+%Y-%m-%d-%H:%M:%S") USER STOPPING ......" | tee -a $CONFIG_TOOL_LOG_PLOTTER
		ps -ef | grep -v grep | grep bladebit_cuda | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1
		exit
	fi
}

