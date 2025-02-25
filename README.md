# CVE漏洞处理

## 拉取代码

```
git clone http://192.168.10.152/lixuebing/cve-processing.git
```
## 脚本说明

patch-clone.sh、update-clone.sh、compile.sh、upload.sh 文件均放在 ~ 目录下，并在 ~ 目录下执行
```
cd ./cve-processing
cp patch-clone.sh update-clone.sh compile.sh upload.sh ~/
```

## 增加可执行性权限

```
cd ~
chmod +x patch-clone.sh update-clone.sh compile.sh upload.sh
```

## 打补丁修复漏洞

### 第1步
拉取cq仓库代码，并将代码拷贝在 rpmbuild 目录下
```
./patch-clone.sh 包名
```

### 第2步
加入补丁，修改spec文件

### 第3步
编译
```
./compile.sh
```

### 第4步
手动修改 upload.sh 中的 commit 内容

### 第5步
上传到 gitlab(cq仓库)，备份软件包到 ~/CVE/package
```
./upload.sh 包名
```

## 升级版本修复漏洞

### 第1步
拉取龙蜥仓库某分支代码，拉取cq仓库主分支代码
```
./update-clone.sh 包名 分支名 
```
拉取欧拉仓库某分支代码，拉取cq仓库主分支代码
```
./update-clone.sh 包名 分支名 1
```

### 第2步
对比 spec 文件，进行修改，并更新相应资源文件

### 第3步
编译
```
./compile.sh
```

### 第4步
手动修改 upload.sh 中的 commit 内容

### 第5步
上传到 gitlab(cq仓库)，备份软件包到 ~/CVE/package
```
./upload.sh 包名
```