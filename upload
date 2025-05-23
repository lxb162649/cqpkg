#!/bin/bash

# 帮助信息
help_msg() {
    cat <<EOF
功能说明：
将本地代码上传至GitLab仓库指定分支，并支持提交信息规范

使用语法：
upload <包名> <分支名> "<提交信息>"

参数说明：
  <包名>        必需，目标仓库名称（如：felix-scr）
  <分支名>      必需，目标分支（如：dev/test）
  <提交信息>    必需，遵循规范（如："修复(spec): 优化SPEC文件"）

规范示例：
- 文档更新："文档(README): 更新安装步骤"
- SPEC修复："修复(spec): 移除无效宏定义"
- 上游同步："更新(同步欧拉仓库): 同步版本2.12.1"
- 上游同步："更新(同步龙蜥仓库): 同步版本2.12.1"
- 架构适配："适配(x86_64): 修复编译警告"

操作流程：
1. 选择代码来源（~/rpmbuild 或当前目录）
2. 自动清理/复制文件
3. 提交到指定分支并创建备份

示例：
upload nginx main "更新(龙蜥): 同步2.18.0版本"
EOF
}

# 参数校验
if [[ $1 == "-h" || $1 == "--help" ]]; then
    help_msg
    exit 0
fi

package_name=$1
branch=$2
commit_msg=$3  # 更清晰的变量名
package_path=$(realpath $package_name)
# 检查必填参数
if [ -z "$package_name" ] || [ -z "$branch" ] || [ -z "$commit_msg" ]; then
    echo "错误：缺少必填参数（包名、分支、提交信息）" >&2
    help_msg
    exit 1
fi

# 交互式确认
read -p "是否从 ~/rpmbuild 目录上传代码？(y/yes/其他跳过): " choice
choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

# 代码复制逻辑
if [[ "$choice" =~ ^(y|yes)$ ]]; then
    echo "正在从 ~/rpmbuild 复制代码..."
    # 清理旧文件（使用绝对路径避免误删）
    rm -rf "$package_path/BUILD" "$package_path/SOURCES" "$package_path/SPECS" "$package_path/SOURCEINFO.yaml"
    # 复制文件（保留目录结构）
    cp -rf ~/rpmbuild/. "$package_path/" || {
        echo "错误：复制文件失败" >&2
        exit 1
    }
else
    echo "使用当前目录代码：$package_path"
fi

# 进入仓库目录
cd "$package_path" || {
    echo "错误：目录不存在：$package_path" >&2
    exit 1
}

# 分支管理
git branch -M "$branch"  # 强制切换/创建分支
git checkout "$branch"    # 确保在目标分支

# 提交代码
git add .
git commit -m "$commit_msg" || {
    echo "错误：提交失败，可能无变更" >&2
    exit 1
}

# 推送至远程仓库
echo "正在推送至 origin/$branch..."
git push -uf origin "$branch" || {
    echo "错误：推送失败，请检查网络和权限" >&2
    exit 1
}

# 备份RPM包
create_backup() {
    local backup_dir="../success/RPMS"
    mkdir -p $backup_dir/{noarch,x86_64}
    
    # 备份noarch架构包
    if ls -1 $package_path/RPMS/noarch/*.rpm &> /dev/null; then
        cp -v $package_path/RPMS/noarch/*.rpm "$backup_dir/noarch/"
    fi
    
    # 备份x86_64架构包
    if ls -1 $package_path/RPMS/x86_64/*.rpm &> /dev/null; then
        cp -v $package_path/RPMS/x86_64/*.rpm "$backup_dir/x86_64/"
    fi
}

# 执行备份（仅当存在RPM文件时）
if [ "$(ls -A RPMS 2>/dev/null)" ]; then
    echo "创建备份到 ../success/RPMS"
    create_backup
else
    echo "警告：未找到RPM文件，跳过备份"
fi

echo "操作完成！代码已推送至 $branch 分支"