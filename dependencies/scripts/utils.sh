#!/bin/bash

# print message to stderr , if need and will exit
function error_message()
{
    local message=$1
#    echo "ERROR - ${message}" >&2
    echo "ERROR - ${message}"
    exit 1
}

# print message to stderr , if need and will exit
function error_message_without_exit()
{
    local message=$1
#    echo "ERROR - ${message}" >&2
    echo "ERROR - ${message}"
}

#exit direct
function error_exit()
{
    exit 1
}

#check if the port is used: 1 in use , 0 not in use
function check_port()
{
    local port=$1
    local times=$2

    if [ -z "$times" ] || [ $times -le 1 ];then
        if sudo lsof -Pi :$port -sTCP:LISTEN  ;then
            return 1
        else
            return 0
        fi
    fi

    local index=0
    while [ $index -lt $times ]
    do
        if sudo lsof -Pi :$port -sTCP:LISTEN  ;then
            return 1
        fi
        sleep 1
        index=$(($index+1))
    done

    return 0
}

function is_valid_ip()
{
    if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function print_dash()
{
    local columns=$(tput cols)
    for((j=0;j<${columns};j++))
    do
        echo -n "-";
    done
}

function print_install_result()
{
    local output_message=$1
    echo "    Installing : ${output_message}"
    return 0
}

function print_install_info()
{
    local output_message=$1
    echo "          info : ${output_message}"
    return 0
}


function get_dir_name()
{
    local dir_path=$1
    dir_name="${dir_path##*/}"
    echo $dir_name
}
# how to use:
# spinner $! "Installing..."
spinner()
{
    local pid=$1
    local info=$2
    local delay=0.1
    local spinstr='|/-\'
    echo -n $info
    while [ "$(ps a | awk '{print $1}' | grep $pid)"  ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo
}

function replace_dot_with_underline()
{
    echo $1 | sed -e "s/\./_/g"
}

function get_randomid()
{
    local random_id=$(head -c 8 /proc/sys/kernel/random/uuid)
    echo $random_id
}
#check if file exist  0-true 1-false
function check_file_exist()
{
    local file_name=$1
    if ! [ -f ${file_name} ]
    then
        return 1
    fi
    return 0
}

#check if file empty 0-true 1-false
function check_file_empty()
{
    local file_name=$1
    if [ -s ${file_name} ];then
        return 1
    fi

    return 0
}

#tar file or dictionary
function tar_tool()
{
    local file=$1
    if [ -f $file".tar.gz" ];then
        echo $file".tar.gz already exist ~"
    else
        tar -zcf $file".tar.gz" $file
    fi
}
