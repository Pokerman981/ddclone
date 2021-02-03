error="\033[31m"
success="\033[32m"
info="\033[36m"
reset="\033[0m"
printf "${info}Data Duplicator - Version 1.0\n\n"

printf "${success}THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, \nINCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. \nIN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, \nDAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,\nARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE\nOR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n\n"

printf "${error}IF YOU DO NOT KNOW HOW TO USE THIS SCRIPT, STOP HERE!\n\n"

pvpkg=$(which pv)
ddpgk=$(which dd)
lsblkpkg=$(which lsblk)

if [ -z "$pvpkg" ]
	then
	printf "You must install the pv program!"
	exit -1
fi

if [ -z $ddpgk ]
	then
	printf "You must install the dd program!"
	exit -1
fi

if [ -z $lsblkpkg ]
	then
	printf "You must install the lsblk program"
	exit -1
fi

source="$1"
target="$2"

if [ -z $source ]
	then
	printf "${error}You must supply a source drive!\n"
	exit -2
fi

if [ -z $target ]
	then
	printf "${error}You must supply a target drive!\n"
	exit -2
fi

if [ $source == $target ]
	then
	printf "${error}Source drive and target drive cannot be the same!\n"
	exit -2
fi

printf "${success}Source Drive"
printf "\n${info}"

lsblk /dev/$source

printf "\n"
printf "${success}Target Drive"
printf "\n${info}"

lsblk /dev/$target

partitionTargetCount=0
usedcount=0
querytargetdrive=$(lsblk -l -n -b -o FSUSEd /dev/$target | sed 1d)

for item in $querytargetdrive
	do
	let "partitionTargetCount+=1"
	let "usedcount = usedcount + item"
	done

if [ "$usedcount" != "0" ]
	then
	printf "\n${error}Drive ${target} has ${partitionTargetCount} partition(s),\n"
	printf "and has ${usedcount} bytes on disk, wipe the drive before cloning!\nExiting..\n"
	exit -3
fi
printf "\n"


partitionSourceCount=0
sourcecount=0
sourcesize=0
querysourcedrive=$(lsblk -l -n -b -o FSUSEd /dev/$source | sed 1d)
querysourcesize=$(lsblk -l -n -b -o FSSIZE /dev/$source | sed 1d)

for item in $querysourcedrive
        do
        let "partitionSourceCount+=1"
        let "sourcecount = sourcecount + item"
        done

for item in $querysourcesize
	do
	let "sourcesize = sourcesize + item"
	done

printf "${success}Drive ${source} has ${partitionSourceCount} partition(s),\n"
printf "and has ${sourcecount} bytes on disk,\n"
printf "and a clone size of ${sourcesize} bytes, starting clone momentarily...\n"

printf "\n${info}Are you sure you want to clone drive ${target}? Y/N\n"

read confirm

printf "\n"
if [ "$confirm" != "Y" ]
	then
	printf "Exiting..\n"
	exit -1
fi

if [ "$EUID" -ne 0 ]
	then
	printf "\n${error}You must run the script as root to clone!\n"
	exit -4
fi

dd if=/dev/$source conv=sync,noerror | pv -s $sourcecount | dd of=/dev/$target

printf "${reset}"
#sudo dd if=/dev/sda bs=4096 count=2481920 conv=sync,noerror | pv -s 9G |sudo dd of=/dev/sdb
#df --outpu=used -h | sed 1d
