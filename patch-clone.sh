#!/bin/bash

rm -rf rpmbuild
rm -rf $1

git clone http://192.168.10.152/cyos-security/public/$1.git

mkdir rpmbuild

# 将clone的代码移动到rpmbuild中
cp -rf $1/* rpmbuild/