#!/bin/bash

rm -rf CVE/package/$1_ok
# 创建目录
mkdir -p CVE/package/$1_ok

# 删除cq仓库里的主要文件
rm -rf ~/$1/BUILD
rm -rf ~/$1/SOURCES
rm -rf ~/$1/SPECS

# 拷贝已经编译好的文件到CQ仓库
cp -rf ~/rpmbuild/BUILD ./$1/
cp -rf ~/rpmbuild/SOURCES ./$1/
cp -rf ~/rpmbuild/SPECS ./$1/
cp -rf ~/rpmbuild/SOURCEINFO.yaml ./$1/

cd $1

# 建立分支
git branch -M dev

# 将所有文件进行打包至预发区并说明提交信息
git add .
# git commit -m "同步至欧拉openEuler-22.03-LTS-SP4分支"
git commit -m "Fix CVE-2024-49761"

# 上传/提交到gitlab的$2分支中
git push -uf origin dev

cd ~
# 做个备份
mv -rf $1/* CVE/package/$1_ok/