#!/bin/bash

#echo $1 
#echo $2 
#echo $# 
#echo $*

# $1 source 
# $2 Destination
# $3 Block amount size 

echo $(date)
ssize1=0
ssize2=0

if [[ $# -eq 0 ]]; then 
      printf "No arguments Supplied\n"
      printf "arg1 Source\n"
      printf "arg2 Destination\n"
      #echo arg3 number of blocks to split the comparison 
      exit 65
fi

##if [[ -z "$3" ]]; then
##     bnumber=100 
##else 
##	bnumber=$3
##fi
# echo $bnumber

if [[ -b $1 ]]; then 
# total size should be always equal
# blockdevice call : blockdev --getsize64 /dev/sdyyy
    ssize1=$(sudo blockdev --getsize64 $1)
    ssize2=$(sudo blockdev --getsize64 $2)
fi

if [[ -f $1 ]]; then 
# filecall : ls -lb $1 | cut -d' ' -f5
    ssize1=$(ls -l $1 | cut -d' ' -f5) 
    ssize2=$(ls -l $2 | cut -d' ' -f5) 
fi

if [[ $ssize1 -gt $ssize2 ]]; then 
    echo Source is to big for Destination
    echo $ssize1  Source
    echo $ssize2  Destination
    exit 66
fi

## dinamic bnumber value according to available RAM 
SHBlocks=$(df -B 512 /dev/shm | cut -d" " -f 17)
bnumber=$(($SHBlocks/(16*512))) 

Nblocks=$(($ssize1 / 512))

echo $Nblocks
bnumber2=$(($Nblocks / 256))

while [ "$bnumber" -lt "$bnumber2" ]; do
	bnumber2=$(($bnumber2 / 16))
done

echo $bnumber 
echo $bnumber2

#bnumber=$bnumber2

pos1=0

tmpf1="/dev/shm/t1a"
tmpf2="/dev/shm/t2a"

while [ "$pos1" -lt "$Nblocks" ]; do

   dd skip=$pos1 if=$1 of=$tmpf1 count=$bnumber status=none
   dd skip=$pos1 if=$2 of=$tmpf2 count=$bnumber status=none
   crc1=$(sha512sum -b $tmpf1 | cut -d' ' -f1 )
   crc2=$(sha512sum -b $tmpf2 | cut -d' ' -f1 )

   if [[ "$crc1" != "$crc2" ]]; then 
      echo $pos1 Different 
      #echo $crc1
      #echo $crc2
      dd seek=$pos1 if=$tmpf1 of=$2 count=$bnumber conv=noerror,fsync,notrunc,sync 
   fi

   pos1=$(( "$pos1" +( "$bnumber" ))) 
   
   #echo $pos1
   #read -p "Press key"
   rm -f $tmpf1
   rm -f $tmpf2
done


echo $(date)
echo DD Sync complete 

