# CVE漏洞处理

## 拉取代码

```
git clone http://192.168.10.152/lixuebing/cve-processing.git
```

## 打补丁修复漏洞

### 第1步
拉取cq仓库代码
```
./clone.sh 包名
```

### 第2步
包名目录下
加入补丁，修改 spec 文件

### 第3步
编译
```
./compile.sh 包名
```

### 第4步
上传到 gitlab(cq仓库)
```
./upload.sh 包名 分支名 commit内容
```

## 升级版本修复漏洞

### 第1步
拉取龙蜥或欧拉仓库某分支代码，拉取cq仓库主分支代码
```
./update-clone.sh 包名 分支名
```

### 第2步
对比 spec 文件，进行修改，并更新相应资源文件

### 第3步
编译
```
./compile.sh
```

### 第4步
上传到 gitlab(cq仓库)，rpm 包放在 success/RPMS 中
```
./upload.sh 包名 分支名 commit内容
```