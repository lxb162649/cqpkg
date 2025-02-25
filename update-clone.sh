#!/bin/bash
#### 功能：将龙蜥仓库的 rpm包 的指定分支拉下来并放到rpmbuild中

## 参数1：要从龙蜥仓库克隆的包的名称
## 参数2：包的分支(如果是a8.9，请省略)

## 使用方法：
#  ./http.sh <包名> [分支名]     #版本是a8.9省略[分支名]
## 示例：
#  ./http.sh libxcb
#  将拉去 libxcb a8.9分支的包，并放到rpmbuild目录下
rm -rf rpmbuild
rm -rf $1

# 创建 rpmbuild 目录结构
mkdir ~/rpmbuild/{BUILD,SOURCES,SPECS} -p

# 选择分支并且clone
if [ -z "$3" ];then
        if [ -z "$2" ];then
                echo "缺少参数"
                exit 1
        fi
        # 没有第三个参数拉取欧拉仓库
        git clone -b $2 https://gitee.com/src-openeuler/$1.git
else
        # 有第三个参数拉取龙蜥仓库
        git clone -b $2 https://gitee.com/src-anolis-os/$1.git   
fi

# 将clone的代码移动到rpmbuild中
mv $1/*.spec rpmbuild/SPECS/
mv $1/* rpmbuild/SOURCES/
rm $1/ -rf

# 创建SOURCEINFO.yaml文件，填入基本信息
cd rpmbuild
touch SOURCEINFO.yaml
cd ./SPECS
spec_name=$(ls)
cd ..
url=$(awk '/^URL:/ {print $2}' "./SPECS/${spec_name}")
if [ -z "${url}" ];then
        url=$(awk '/^Url:/ {print $2}' "./SPECS/${spec_name}")
fi
name=$(awk '/^Name:/ {print $2}' "./SPECS/${spec_name}")
license=`grep "License:" SPECS/*.spec | sed 's/License:[[:space:]]*//'`
echo "license:" > "SOURCEINFO.yaml"
echo "- ${license}" >> "SOURCEINFO.yaml"

echo "origin:" >> "SOURCEINFO.yaml"
echo "  src: ${url}" >> "SOURCEINFO.yaml"

echo "upstream:" >> "SOURCEINFO.yaml"
echo "  branch: $2" >> "SOURCEINFO.yaml"

if [ -z "$3" ];then
        echo "  src: https://gitee.com/src-openeuler/$1.git" >> "SOURCEINFO.yaml"
else
        echo "  src: https://gitee.com/src-anolis-os/$1.git" >> "SOURCEINFO.yaml"
fi

cd ~
# 拉取cq仓库里的包
git clone http://192.168.10.152/cyos-security/public/$1.git