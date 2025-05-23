#!/bin/bash

# 帮助信息
help_msg() {
    cat <<EOF
功能说明：
- 自动安装编译依赖、构建RPM包并展示结果
- 支持两种模式：
  1. 全局模式：基于默认的 ~/rpmbuild 目录
  2. 本地模式：基于指定的源码包目录

使用语法：
compile [包名]

参数说明：
  [包名] 可选，源码包目录名（默认使用 ~/rpmbuild）

示例：
1. 全局模式（编译~/rpmbuild中的SPEC文件）：
   compile

2. 本地模式（编译指定目录中的包）：
   compile felix-scr
EOF
}

# 参数校验
if [[ $1 == "-h" || $1 == "--help" ]]; then
    help_msg
    exit 0
fi

package_name=$1

# 确定工作目录
if [ -z "$package_name" ]; then
    work_dir=~/rpmbuild
    spec_pattern="$work_dir/SPECS/*.spec"
else
    work_dir=$(realpath "$package_name")
    spec_pattern="$work_dir/SPECS/*.spec"
    
    if [ ! -d "$work_dir" ]; then
        echo "错误：目录不存在：$work_dir" >&2
        exit 1
    fi
fi

# 安装编译依赖
install_deps() {
    echo "正在安装编译依赖..."
    if ! yum builddep -y $spec_pattern; then
        echo "安装依赖失败" && exit 1
    fi
}

# 构建RPM包
build_rpm() {
    local build_args=()

    cd $work_dir
    if [ "$work_dir" != "$HOME/rpmbuild" ]; then
        build_args+=(-D "_topdir $(pwd)")  # 设置自定义TOPDIR
    fi
    
    echo "开始构建RPM包..."

    rpmbuild -ba "${build_args[@]}" $spec_pattern || {
        echo "错误：RPM构建失败" >&2
        exit 1
    }
	echo "RPM构建成功"
	rpmbuild -bp "${build_args[@]}" $spec_pattern
}

# 展示构建结果
show_results() {
    local rpms_dir="${work_dir}/RPMS"
    
    if [ ! -d "$rpms_dir" ]; then
        echo "警告：未生成RPM文件"
        exit 1
    fi
    
    echo -e "\n构建结果："
    for arch in noarch x86_64; do
        local arch_dir="$rpms_dir/$arch"
        echo "== $arch =="
        if [ "$(ls -A "$arch_dir" 2>/dev/null)" ]; then
            ls -1 "$arch_dir"
        else
            echo "无"
        fi
        echo
    done
}

# 主流程
install_deps
build_rpm
show_results