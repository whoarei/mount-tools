#! /bin/bash

PARTLABEL_DIR="/dev/disk/by-partlabel/"
PART_LINEAGEOS="/dev/disk/by-partlabel/lineageos"
PART_AOSP="/dev/disk/by-partlabel/aosp"
PART_ALL="/dev/disk/by-partlabel/all"

function error() {
    echo -e "\e[31m"$1"\e[0m"
}

function info() {
    echo "$1"
}


#   $1: mount point
function mount_point_to_device() {
    local abspath="$1"
    [ -z `echo $1 | awk '/^\/.*/ {print $0}'` ] && abspath="/mnt/$1"
    echo `mount|awk '\$3 == "'$abspath'" {print \$1}'`
}

function device_to_mount_point() {
    local real_device="`realpath $1`"
    [ ! -b $real_device ] && exit 0
    echo `mount|awk '\$1 == "'$real_device'" {print \$3}'`
}

#   $1: partation lable
function partlabel_to_device() {
    local abspath="$1"
    [ -z `echo $1 | awk '/^\/.*/ {print $0}'` ] && abspath="/dev/disk/by-partlabel/$1"
    realpath=`realpath $abspath`
    [ -e $realpath ] && echo $realpath
}

#   通过partlabel挂载分区到/mnt/partlabel
#   创建$HOME目录的软连接到挂载点或者挂载点
#   软连接可以链接到分区的子目录，子目录目录以$2传入
#
#   $1: partlabel_path by partlabel
#   $2: access path, optional
mount_by_partlabel() {
    local partlabel_path="$1"
    [ -z `echo $partlabel_path | awk '/^\/.*/ {print $0}'` ] && partlabel_path="$PARTLABEL_DIR/$1"
    local partlabel=`basename $partlabel_path`
    local mount_point=/mnt/$partlabel

    #   device not exist
    [ ! -e $partlabel_path ] && error "$partlabel_path not exist" && exit 0

    #   if device is already mounted
    local mp_device="`mount_point_to_device $mount_point`"
    local pl_device="`partlabel_to_device $partlabel`"
    if [ -n "$mp_device" ] && [ "$mp_device" != "$pl_device" ];then
        error "cannot mount to $mount_point"
        error "$partlabel_path already mount to `device_to_mount_point $mount_point`"
        exit
    fi

    [ ! -e $mount_point ] && sudo mkdir -p $mount_point
    
    [ -z "$mp_device" ] && sudo mount -v $partlabel_path $mount_point

    local access_dir=$mount_point/$2
    local linkpath=$access_dir
    linkpath=`echo $linkpath|awk 'gsub("^\/+", "")'`
    linkpath=`echo $linkpath|awk 'gsub("\/*$", "")'`
    linkpath=`echo $linkpath|awk 'gsub("\/+", "/")'`
    linkpath=`echo $linkpath|awk 'gsub("\/", "_")'`
    linkpath=$HOME/$linkpath
    echo $linkpath
    echo $access_dir
    [ -L $linkpath ] && rm -rf $linkpath
    ln -svf "$access_dir" "$linkpath"
}

mount_by_partlabel "$PART_ALL" "mmeng"
mount_by_partlabel "$PART_AOSP"
mount_by_partlabel "$PART_LINEAGEOS"

