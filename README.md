# cq软件包管理

## 修改环境

首次使用该项目运行
```
cp -f $(find ~ -name cqpkg_manager)/pkg_env_init.sh /usr/bin/pkg_env_init
```
以后运行
```
pkg_env_init
```
## 处理

### 第1步
拉取仓库代码
```
clone 包名 分支名
```

### 第2步
修改 spec 文件

### 第3步
编译
```
compile 包名
```

### 第4步
上传到 gitlab(cq仓库)
```
upload 包名 分支名 commit内容
```