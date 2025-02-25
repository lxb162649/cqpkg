#!/bin/bash

# 安装编译 *.spec 文件所需的软件包
yum builddep -y ./rpmbuild/SPECS/*.spec

# 编译后做成*.rpm和src.rpm
rpmbuild -ba ./rpmbuild/SPECS/*.spec

# 只作准备 （解压与打补丁）
rpmbuild -bp ./rpmbuild/SPECS/*.spec 