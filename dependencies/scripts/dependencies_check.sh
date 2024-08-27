#!/bin/bash

#check user has sudo permission
function request_sudo_permission()
{
    sudo echo -n " "

    if [ $? -ne 0 ]; then
        error_message "no sudo permission, please add youself in the sudoers"
    fi
}

#check if $1 is install
function check_if_install()
{
    type $1 >/dev/null 2>&1
    if [ $? -ne 0 ];then
        error_message "$1 is not installed."
    fi
}

#check if $1 is install, return 0-already install; 1-not install
function check_if_install_without_exit()
{
    type $1 >/dev/null 2>&1
    if [ $? -ne 0 ];then
        return 1
    fi
    return 0
}

#Oracle JDK 1.8 be requied.
function java_version_check()
{
    check_if_install java

    check_if_install keytool

    #JAVA version
    JAVA_VER=$(java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*".*/\1\2/p;')

    if [ -z "$JAVA_VER" ];then
        error_message "failed to get java version, version is `java -version 2>&1 | grep java`"
    fi

    #Oracle JDK 1.8
    if [ $JAVA_VER -eq 18 ] && [[ $(java -version 2>&1 | grep "TM") ]];then
        #is java and keytool match ?
        JAVA_PATH=$(dirname `which java`)
        KEYTOOL_PATH=$(dirname `which keytool`)
        if [ "$JAVA_PATH" = "$KEYTOOL_PATH" ];then
            echo " java path => "${JAVA_PATH}
            echo " keytool path => "${KEYTOOL_PATH}
            return
        fi

        error_message "Oracle JDK 1.8 be required, now JDK is `java -version 2>&1 | grep java`"
        #error_message "java and keytool is not match, java is ${JAVA_PATH} , keytool is ${KEYTOOL_PATH}"
    fi

   error_message "Oracle JDK 1.8 be required, now JDK is `java -version 2>&1 | grep java`"
}

#maven 3.3.9 be required
function maven_version_check()
{
    check_if_install mvn
    #maven version
     if [[ -z $(mvn -version |grep "3.3.9") ]]; then
    error_message "Maven version 3.3.9 be required , now Maven version is `mvn -version`"
    fi

}

#openssl 1.0.2 be required.
function openssl_version_check()
{
    check_if_install openssl

    #openssl version
    OPENSSL_VER=$(openssl version 2>&1 | sed -n ';s/.*OpenSSL \(.*\)\.\(.*\)\.\([0-9]*\).*/\1\2\3/p;')

    if [ -z "$OPENSSL_VER" ];then
        error_message "failed to get openssl version, version is "`openssl version`
    fi

    #openssl 1.0.2
    if [ $OPENSSL_VER -eq 102 ];then
        return 0
    fi

    return 1
}

function dependencies_pre_check()
{
    # operating system check => CentOS 7.2+ || Ubuntu 16.04 || Oracle Linux Server 7.4+
    os_version_check
    # java => Oracle JDK 1.8
    java_version_check
    #maven version>=3.3.9
    maven_version_check
    #bouncycastle package must be in $JAVA_HOME/jre/lib/ext，这里因为在使用thanos-common可执行jar包生成密钥对时，由于该包是fat-jar，里面的密码包是被重新打包的。
    # 当代码运行到JCE库时，会校验密码包的签名，并提示签名不可信（thanos-common重新打包导致的）。因此，需要把用到的密码包原封不动（签名可信）的放到$JAVA_HOME/jre/lib/ext目录下。
    check_and_install_bc_java ${DEPENDENCIES_JAR_DIR}
}

function check_and_install_bc_java()
{
    local src_jar_path=$1
    local target_path=$JAVA_HOME/jre/lib/ext
    local src_path=${DEPENDENCIES_JAR_DIR}
    local jar_name="bcprov-jdk15on-1.66.jar"
    if ! [ -f ${target_path}/${jar_name} ]
    then
        cp ${src_jar_path}/$jar_name $target_path
    fi
}

# version check
function build_dependencies_check()
{
    #gmssl
    check_if_install gmssl
    # git
    check_if_install git
    # lsof
    check_if_install lsof
    # envsubst
    check_if_install envsubst
    # xxd
    check_if_install xxd
    # crudini
    check_if_install crudini

    # add more check here
}

#check if any dependency not install. return 0: all has install; 1:has dependency not install yet.
function build_dependencies_check_without_exit()
{
    # gmssl
    check_if_install_without_exit gmssl
    if [ $? -ne 0 ]; then
        return 1
    fi
    # git
    check_if_install_without_exit git
        if [ $? -eq 1 ];then
        return 1
    fi
    # lsof
    check_if_install_without_exit lsof
    if [ $? -eq 1 ];then
        return 1
    fi
    # envsubst
    check_if_install_without_exit envsubst
    if [ $? -eq 1 ];then
        return 1
    fi
    # xxd
    check_if_install_without_exit xxd
    if [ $? -eq 1 ];then
        return 1
    fi
    # crudini
    check_if_install_without_exit crudini
    if [ $? -eq 1 ];then
        return 1
    fi
    # add more check here
    return 0
}
