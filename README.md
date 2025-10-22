# 目录

- [简介](#简介)
- [使用场景](#使用场景)
- [常见用法](#常见用法)
- [注意事项](#注意事项)

# 简介

本项目主要包含cq系统软件包管理，针对所有用户使用rpm安装，针对当前用户可以进入SOURCES目录make install安装

# 引入说明

暂不引入

# 使用场景

克隆、编译、上传代码

# 用户安装
```bash
git clone https://github.com/lxb162649/cqpkg.git
cd cqpkg/SOURCES
make install
cd -
```

# root安装
```bash
git clone https://github.com/lxb162649/cqpkg.git
cd cqpkg
rpmbuild -ba -D "_topdir `pwd`" SPECS/*.spec
yum install -y "$(find RPMS -name *.rpm)"
cd -
```

# 常见用法

- **克隆**
```bash
# 查看帮助信息
cqpkg -h

# 当前目录不存在sos
cqpkg sos 

# 当前目录存在sos
cqpkg sos -cl
```

- **编译**
```bash
cqpkg sos -co
```

- **上传**
```bash
cqpkg sos -u

# 返回上次提交然后上传
cqpkg sos -reu
```

- **翻译man手册**
```bash
# 克隆
cqpkg sos

# 解压man手册到sos/SOURCES/man目录下
cqpkg sos -e

# 翻译sos/SOURCES/man目录下的man手册（可多个终端同时执行此命令以加快翻译速度）
cqpkg sos -tr

# 将翻译好的man手册以补丁形式打入并自动修改spec文件
cqpkg sos -p

# 编译，可检查man手册是否安装成功
cqpkg sos -co

# 提交
cqpkg sos -u

# 创建合并请求
cqpkg sos -mr
```

# 注意事项

- 如果参数想用包名而不使用路径，需要此包在当前目录下。
- 龙蜥或欧拉的隐藏文件可能会缺失。
- 如果当前编译生成的rpm包版本小于yum仓库里的包版本，则在检查man手册是否安装成功时不能安装编译生成rpm包，需手动处理

