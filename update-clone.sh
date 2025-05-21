#!/bin/bash

source "function.sh"

if [[ $1 == "-h" || $1 == "--help" ]]; then
    cat << EOF
功能1：将龙蜥或欧拉仓库的源码包的指定分支拉下来并放到 ~/rpmbuild 中
功能2：创建 yaml 文件，自动获取开源协议、上游、分支、顶级社区
功能3：拉取对应 gitlab 仓库

参数1：要从龙蜥或欧拉仓库克隆的包的名称
参数2：包的分支

1.拉龙蜥仓库
./update-clone.sh <包名> [分支名]
示例：
./update-clone.sh felix-scr a8.9
将拉去龙蜥 felix-scr a8.9 分支的包，并放到 ~/rpmbuild 目录下

2.拉龙蜥仓库
./update-clone.sh <包名> [分支名]
示例：
./update-clone.sh felix-scr openEuler-22.03-LTS-SP4
将拉去欧拉 felix-scr openEuler-22.03-LTS-SP4 分支的包，并放到 ~/rpmbuild 目录下
EOF
exit 0
fi

package_name=$1
branch=$2
current_path=$(pwd)

if [ -z "$package_name" ];then
    echo "缺少包名参数，缺少分支参数"
    exit 1
else
	if [ -z "$branch" ];then
		echo "缺少分支参数"
		exit 1
	fi
fi

# 删除原来的仓库
rm -rf $package_name

# 判断从欧拉仓库还是龙蜥仓库拉取代码
read -p "从欧拉仓库还是龙蜥仓库拉取 $package_name 代码？(输入 a 从欧拉拉取 $package_name 代码，其他输则从龙蜥拉取 $package_name 代码)" choice
choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

if [ "$choice" = "a" ]; then
    git clone -b $branch https://gitee.com/src-openeuler/$package_name.git  
else
    git clone -b $branch https://gitee.com/src-anolis-os/$package_name.git 
fi

# 检查是否克隆成功
CHECK_RESULT $? 0 0 "克隆失败，未找到对应仓库或分支" 

# 删除原来的 ~/rpmbuild 目录
rm -rf ~/rpmbuild

# 创建 ~/rpmbuild 目录结构
mkdir ~/rpmbuild/{BUILD,SOURCES,SPECS} -p

# 将clone的代码移动到~/rpmbuild中
mv $package_name/*.spec ~/rpmbuild/SPECS/
mv $package_name/* ~/rpmbuild/SOURCES/
rm $package_name/ -rf

# 创建SOURCEINFO.yaml文件，填入基本信息
cd ~/rpmbuild
touch SOURCEINFO.yaml

# 获取 spec 文件名
cd SPECS
spec_name=$(ls)

cd ..

# 获取顶级上游地址
url=$(awk '/^URL:/ {print $2}' "./SPECS/${spec_name}")
if [ -z "${url}" ];then
    url=$(awk '/^Url:/ {print $2}' "./SPECS/${spec_name}")
fi

# 获取开源协议
license=`grep "License:" SPECS/*.spec | sed 's/License:[[:space:]]*//'`

# 写入开源协议
echo "license:" > "SOURCEINFO.yaml"
echo "  - ${license}" >> "SOURCEINFO.yaml"

# 写入上游社区
echo "upstream:" >> "SOURCEINFO.yaml"
if [ "$choice" = "a" ]; then
    echo "  src: https://gitee.com/src-openeuler/$package_name.git" >> "SOURCEINFO.yaml"
else
    echo "  src: https://gitee.com/src-anolis-os/$package_name.git" >> "SOURCEINFO.yaml"
fi

# 写入上游分支
echo "  branch: $branch" >> "SOURCEINFO.yaml"

# 写入顶级社区
echo "origin:" >> "SOURCEINFO.yaml"
echo "  src: ${url}" >> "SOURCEINFO.yaml"

# 提示用户是否执行命令
read -p "是否要从 CQ 仓库拉取 $package_name 代码？(输入 y 或 yes 执行，其他输入则跳过)" choice2

# 将用户输入转换为小写，方便统一判断
choice2=$(echo "$choice2" | tr '[:upper:]' '[:lower:]')

# 判断用户输入并执行相应操作
if [ "$choice2" = "y" ] || [ "$choice2" = "yes" ]; then
    echo "正在从 CQ 仓库拉取代码..."
    cd $(current_path)
    bash clone.sh $package_name
fi
