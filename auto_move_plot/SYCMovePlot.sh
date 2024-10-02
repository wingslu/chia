PLOT_DIRECTORY="/Chia"
HD_DEST=(
    "/Chia/HDD/HD0"
    "/Chia/HDD/HD1"
    "/Chia/HDD/HD2"
    "/Chia/HDD/HD3"
    "/Chia/HDD/HD4"
    "/Chia/HDD/HD5"
    "/Chia/HDD/HD6"
    "/Chia/HDD/HD7"
    "/Chia/HDD/HD8"
    "/Chia/HDD/HD9"
    "/Chia/HDD/HD10"
    "/Chia/HDD/HD11"
)

strReadyDirectory=$PLOT_DIRECTORY"/Ready"

mkdir -p $strReadyDirectory

intHDCount=${#HD_DEST[@]}
intHDIndex=0

while [ true ]
do

    for strFileName in $(ls $PLOT_DIRECTORY)
    do
        if [ -d $PLOT_DIRECTORY"/"$strFileName ]
        then
            continue
        fi

        strExtName=${strFileName:0-4:4}

        if [ $strExtName != "plot" ]
        then
            continue
        fi

        while [ true ]
        do
            let intMvCount=($(ps -eO lstart | grep mv | wc -l ))

            if [ $intMvCount -lt $intHDCount ]
            then
                break
            fi

            sleep 10
        done

        mv $PLOT_DIRECTORY"/"$strFileName $strReadyDirectory

        while [ true ]
        do
            strCurrentHD=${HD_DEST[$intHDIndex]}

            intSpareSize=0
            let intSpareSize=$(df --block-size=1 $strCurrentHD | sed -n 2p | awk -F " " '{print $4}')

            if [ $intSpareSize -ge 110000000000 ]
            then
                break
            fi

            let intHDIndex=$intHDIndex+1

            if [ $intHDIndex -ge $intHDCount ]
            then
                intHDIndex=0
            fi

            sleep 1
        done

        nohup mv $strReadyDirectory"/"$strFileName $strCurrentHD &

        let intHDIndex=$intHDIndex+1

        if [ $intHDIndex -ge $intHDCount ]
        then
            intHDIndex=0
        fi

    done

    sleep 60
done


