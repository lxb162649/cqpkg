#!/bin/bash

source "function.sh"

if [[ $1 == "-h" || $1 == "--help" ]]; then
    cat << EOF
功能：将代码上传到 gitlab 仓库指定分支，并提供提交信息

参数1：要从龙蜥或欧拉仓库克隆的包的名称
参数2：包的分支
参数3：提交信息

使用方法
1.上传代码
./upload.sh 包名 分支 提交信息
示例：
./upload.sh felix-scr dev "文档(README): 更新README文件"
将代码上传到 felix-scr 的 dev 分支，提交信息为 "文档(README): 更新README文件"
"修复(spec): 移除anolis_release、rhel宏"
"修复(spec): 移除rhel宏"
"更新(同步欧拉仓库)：同步版本-2.12.1"
"更新(同步龙蜥仓库)：同步版本-2.12.1"
EOF
exit 0
fi

package_name=$1
branch=$2
commit=$3

if [ -z "$package_name" ];then
    echo "缺少包名参数，缺少分支参数，缺少提交信息参数"
    exit 1
else
	if [ -z "$branch" ];then
    	echo "缺少分支参数，缺少提交信息参数"
    	exit 1
	else
		if [ -z "$commit" ];then
			echo "缺少提交信息参数"
			exit 1
		fi	
	fi
fi

# 提示用户是否执行命令
read -p "是否要从 rpmbuild 目录下上传代码？(输入 y 或 yes 执行，其他输入则跳过)" choice

# 将用户输入转换为小写，方便统一判断
choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

# 判断用户输入并执行相应操作
if [ "$choice" = "y" ] || [ "$choice" = "yes" ]; then
    echo "正在从 rpmbuild 目录下上传代码..."
    # 删除cq仓库里的主要文件
	rm -rf $package_name/BUILD
	rm -rf $package_name/SOURCES
	rm -rf $package_name/SPECS
	rm -rf $package_name/SOURCEINFO.yaml

	# 拷贝已经编译好的文件到CQ仓库
	cp -rf rpmbuild/* $package_name/
else
    echo "正在从 $package_name 目录下上传代码..."
fi

cd $package_name
CHECK_RESULT $? 0 0 "不存在 $package_name 目录" 

# 建立分支
git branch -M $branch

# 将所有文件进行打包至预发区并说明提交信息
git add .
git commit -m "$commit"

# 上传/提交到gitlab的$2分支中
git push -uf origin $branch

cd ..

# 做个备份
if [ -f $package_name/RPMS ]; then
	mkdir success
	cp -rf $package_name/RPMS success/
fi
