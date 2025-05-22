#!/bin/bash

source "function.sh"

if [[ $1 == "-h" || $1 == "--help" ]]; then
        cat << EOF
功能：安装依赖、编译并解压

参数1：要从龙蜥或欧拉仓库克隆的包的名称

使用方法
1.编译 ~/rpmbuild 目录下的包
./compile.sh
示例：
./compile.sh
将在 ~/rpmbuild 目录下安装依赖、编译并解压

2.编译源码目录下的包
./compile.sh 包名
示例：
./compile.sh felix-scr
将在 felix-scr 目录下安装依赖、编译并解压
EOF
exit 0
fi

package_name=$1

if [ -z "$package_name" ];then
    # 安装编译 *.spec 文件所需的软件包
	yum builddep -y ~/rpmbuild/SPECS/*.spec
	CHECK_RESULT $? 0 0 "安装依赖失败"

	# 编译后做成*.rpm和src.rpm
	rpmbuild -ba ~/rpmbuild/SPECS/*.spec

	file_count=$(ls -A ~/rpmbuild/RPMS | wc -l)
	if [ $file_count -gt 0 ]; then
		# 只作准备 （解压与打补丁）
		rpmbuild -bp ~/rpmbuild/SPECS/*.spec
		echo ""
		echo "noarch"
		echo "$(ls -A ~/rpmbuild/RPMS/noarch)"
		echo "x86_64"
		echo "$(ls -A ~/rpmbuild/RPMS/x86_64)"
		echo ""
	fi
else
	# 安装编译 *.spec 文件所需的软件包
	cd $package_name
	CHECK_RESULT $? 0 0 "不存在 $package_name 目录" 

	yum builddep -y SPECS/*.spec
	CHECK_RESULT $? 0 0 "安装依赖失败"

	# 编译后做成*.rpm和src.rpm
	rpmbuild -ba -D "_topdir `pwd`" SPECS/*.spec

	file_count=$(ls -A RPMS | wc -l)
	if [ $file_count -gt 0 ]; then
		# 只作准备 （解压与打补丁）
		rpmbuild -bp -D "_topdir `pwd`" SPECS/*.spec
		echo ""
		echo "noarch"
		echo "$(ls -A RPMS/noarch)"
		echo "x86_64"
		echo "$(ls -A RPMS/x86_64)"
		echo ""
	fi
fi
