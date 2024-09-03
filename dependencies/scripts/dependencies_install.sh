#!/bin/bash

module_name="install.sh"

# uname -v > /dev/null 2>&1 || { echo >&2 "ERROR - ${myname} use 'uname' to identify the platform."; exit 1; }
# case $(uname -s) in
#   Darwin)
#       ;;
#   Linux)
#            if [ ! -f "/etc/os-release" ];then
#                   { echo >&2 "ERROR - Unsupported or unidentified Linux distro."; exit 1; }
#            fi
#            DISTRO_NAME=$(. /etc/os-release; echo $NAME)
#            case $DISTRO_NAME in
#                    Ubuntu*)
#                        ;;
#                    CentOS*)
#                        ;;
#                    Oracle*)
#                        ;;
#                     *)
#                        ;;.
#             esac
#       ;;
#   *)
#       ;;
#   esac

function dependencies_install()
{

    build_dependencies_check_without_exit
    if [ $? -eq 0 ];then
        echo "all dependencies has installed."
        return
    fi

    local myname=$1
    if [ -z $myname ];then
        myname=$module_name
    fi

    # Check for 'uname' and abort if it is not available.
    uname -v > /dev/null 2>&1 || { echo "ERROR - ${myname} use 'uname' to identify the platform."; exit 1; }

    case $(uname -s) in

    #------------------------------------------------------------------------------
    # macOS
    #------------------------------------------------------------------------------
    Darwin)
        case $(sw_vers -productVersion | awk -F . '{print $1"."$2}') in
            *)
                /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
                brew install dos2unix
                brew install openssl
                brew upgrade openssl
                brew link --force openssl

            ;;
        esac #case $(sw_vers

        ;; #Darwin)

    #------------------------------------------------------------------------------
    # Linux
    #------------------------------------------------------------------------------
    Linux)

        if [ ! -f "/etc/os-release" ];then
            error_message "Unsupported or unidentified Linux distro."
        fi

        DISTRO_NAME=$(. /etc/os-release; echo $NAME)
        # echo "Linux distribution: $DISTRO_NAME."

        case $DISTRO_NAME in
    #------------------------------------------------------------------------------
    # Ubuntu  # At least 16.04
    #------------------------------------------------------------------------------
            Ubuntu*)

                    sudo apt-get -y install lsof
                    sudo apt-get -y install crudini
                    sudo apt-get -y install git
                    sudo apt-get -y install gcc
#                    sudo apt-get -y install openssl

                    sudo apt-get -y install uuid-dev
                    sudo apt-get -y install vim-common

                    sudo apt-get -y install gcc-c++
                    install_gmssl
                ;;
    #------------------------------------------------------------------------------
    # CentOS  # At least 7.2
    #------------------------------------------------------------------------------
            CentOS*)
                    #配置yum源为aliyun
                    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
                    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
                    yum clean all
                    yum makecache

                    sudo yum -y install git
#                    sudo yum -y install openssl
                    sudo yum -y install lsof
                    sudo yum -y install crudini
                    sudo yum -y install libuuid-devel
                    sudo yum -y install  vim-common

                    sudo yum -y install gcc-c++
                    install_gmssl
                ;;
    #------------------------------------------------------------------------------
    # Oracle Linux Server # At least 7.4
    #------------------------------------------------------------------------------
            Oracle*)

                    sudo yum -y install lsof
                    sudo yum -y install git
                    sudo yum -y install openssl
                    sudo yum -y install crudini
                    sudo yum -y install libuuid-devel

                    sudo yum -y install gcc-c++
                    install_gmssl
                ;;
    #------------------------------------------------------------------------------
    # Other Linux
    #------------------------------------------------------------------------------
            *)
                error_message "Unsupported Linux distribution: $DISTRO_NAME."
                ;;
        esac # case $DISTRO_NAME

        ;; #Linux)

    #------------------------------------------------------------------------------
    # Other platform (not Linux, FreeBSD or macOS).
    #------------------------------------------------------------------------------
    *)
        #other
        error_message "Unsupported or unidentified operating system."
        ;;
    esac
}

#安装gmssl ,默认安装在usr/local/bin目录下
function install_gmssl()
{
    echo "starting install gmssl...."
    cd ~
    git clone --branch GmSSL-v2 --single-branch https://github.com/guanzhi/GmSSL.git
    cd GmSSL/
    ./config
    make
    sudo make install
    sudo cp libcrypto.so.1.1 libssl.so.1.1 /lib64
    #export PATH=$PATH:/user/local/bin
    local str="export PATH=/usr/local/bin:\${PATH}"
    local profile="/etc/profile"
    if [ `grep -c "$str" $profile` -eq '0' ]; then
         echo $str >> $profile
         source $profile
    fi
    #check if install gmssl success
    type gmssl >/dev/null 2>&1
    if [ $? -ne 0 ];then
        error_message "gmssl installed failed. please check and make sure /usr/local/bin is in \$PATH"
    fi
    echo "gmssl install success."
}

function simple_dependencies_install()
{
    local myname=$1
    if [ -z $myname ];then
        myname=$module_name
    fi

    # Check for 'uname' and abort if it is not available.
    uname -v > /dev/null 2>&1 || { echo "ERROR - ${myname} use 'uname' to identify the platform."; exit 1; }

    case $(uname -s) in

    #------------------------------------------------------------------------------
    # macOS
    #------------------------------------------------------------------------------
    Darwin)
        case $(sw_vers -productVersion | awk -F . '{print $1"."$2}') in
            *)
                /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
                brew install gettext
                brew link --force gettext

            ;;
        esac #case $(sw_vers

        ;; #Darwin)

    #------------------------------------------------------------------------------
    # Linux
    #------------------------------------------------------------------------------
    Linux)

        if [ ! -f "/etc/os-release" ];then
            error_message "Unsupported or unidentified Linux distro."
        fi

        DISTRO_NAME=$(. /etc/os-release; echo $NAME)
        # echo "Linux distribution: $DISTRO_NAME."

        case $DISTRO_NAME in
    #------------------------------------------------------------------------------
    # Ubuntu  # At least 16.04
    #------------------------------------------------------------------------------
            Ubuntu*)

                     sudo apt-get -y install crudini
                ;;
    #------------------------------------------------------------------------------
    # CentOS  # At least 7.2
    #------------------------------------------------------------------------------
            CentOS*)

                     #配置yum源为aliyun
                    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
                    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
                    yum clean all
                    yum makecache

                    sudo yum -y install crudini

                ;;
    #------------------------------------------------------------------------------
    # Oracle Linux Server # At least 7.4
    #------------------------------------------------------------------------------
            Oracle*)

                    sudo yum -y install crudini

                ;;
    #------------------------------------------------------------------------------
    # Other Linux
    #------------------------------------------------------------------------------
            *)
                error_message "Unsupported Linux distribution: $DISTRO_NAME."
                ;;
        esac # case $DISTRO_NAME

        ;; #Linux)

    #------------------------------------------------------------------------------
    # Other platform (not Linux, FreeBSD or macOS).
    #------------------------------------------------------------------------------
    *)
        #other
        error_message "Unsupported or unidentified operating system."
        ;;
    esac
}
