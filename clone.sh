#!/bin/bash

source "function.sh"

if [[ $1 == "-h" || $1 == "--help" ]]; then
        cat << EOF
功能：拉取 cq 仓库代码

参数1：包的名称

使用方法
1.拉取主分支代码
./clone.sh 包名
示例：
./clone.sh felix-scr
将拉取 cq 仓库中 felix-scr 的 master 分支代码
2.拉取指定分支代码
./clone.sh 包名 分支名
示例：
./clone.sh felix-scr dev
将拉取 cq 仓库中 felix-scr 的 dev 分支代码
EOF
exit 0
fi

package_name=$1
branch=${2-master}

if [ -z "$package_name" ];then
	echo "缺少包名参数"
	exit 1
fi

rm -rf $package_name

# 拉取cq仓库里的包
repos=(
    "http://192.168.10.152/cyos-security/public/$package_name.git"
    "http://192.168.10.152/cyos-security/protected/$package_name.git"
    "http://192.168.10.152/cyos-security/private/$package_name.git"
    "http://192.168.10.152/cyos-security/trash/$package_name.git"
    "http://192.168.10.152/cyos-security/iso/$package_name.git"
    "http://192.168.10.152/cyos-security/$package_name.git"
    "http://192.168.10.152/cyos-security/toolkits/$package_name.git"
    "http://192.168.10.152/cyos-security/transition/python3.11/$package_name.git"
    "http://192.168.10.152/cyos-security/transition/deb_to_rpm/$package_name.git"
    "http://192.168.10.152/cyos-security/transition/xfce/$package_name.git"
    "http://192.168.10.152/cyos-security/transition/$package_name.git"
	"http://192.168.10.152/lixuebing/$package_name.git"
)

for repo in "${repos[@]}"; do
    git clone -b $branch "$repo"
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "成功克隆 $repo"
        exit 0
    else
        rm -rf $package_name
        echo "克隆 $repo 失败，重试..."
    fi
done