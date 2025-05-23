# 软件包同步或修改

## 拉取代码

```
git clone http://192.168.10.152/lixuebing/cve-processing.git
```

## 处理

### 第1步
拉取仓库代码
```
./clone.sh 包名 分支名
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

### 第4步
上传到 gitlab(cq仓库)，rpm 包放在 success/RPMS 中
```
./upload.sh 包名 分支名 commit内容
```