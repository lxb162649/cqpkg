# 配置本地yum源（包含所有子目录）
setup_local_repo() {
    # 临时yum源配置文件
    local local_repo="/etc/yum.repos.d/local_kyotocabinet.repo"
    # 查找所有RPM子目录（noarch/x86_64/sw_64等）
    local rpm_dirs=$(find "$RPM_DIR" -maxdepth 1 -type d ! -name "$(basename "$RPM_DIR")" -print0 | tr '\0' ' ')
    
    # 创建repo文件
    cat > "$LOCAL_REPO" <<EOF
[local-kyotocabinet]
name=Local Kyotocabinet RPMs
baseurl=$(echo "$rpm_dirs" | sed 's/ /\n        file:\/\//g' | sed 's/^/file:\/\//')
enabled=1
gpgcheck=0
priority=1
EOF
    echo "已配置本地RPM源，包含目录: $rpm_dirs"
}

# 清理临时yum源
cleanup_local_repo() {
    if [ -f "$LOCAL_REPO" ]; then
        rm -f "$LOCAL_REPO"
        echo "已清理本地源配置"
    fi
}

# module_install函数（增强版）
module_install() {
    local rpm_path="$1"
    
    # 检查包是否存在
    if [ ! -f "$rpm_path" ]; then
        echo "错误：RPM包 $rpm_path 不存在"
        return 1
    fi

    # 提取包名和版本
    local pkg_name=$(rpm -qp --queryformat '%{NAME}' "$rpm_path" 2>/dev/null)
    local pkg_version=$(rpm -qp --queryformat '%{VERSION}-%{RELEASE}' "$rpm_path" 2>/dev/null)
    
    if [ -z "$pkg_name" ] || [ -z "$pkg_version" ]; then
        echo "错误：无法解析RPM包信息 $rpm_path"
        return 1
    fi

    # 检查是否已安装同版本
    if rpm -q "$pkg_name" --quiet --version "$pkg_version"; then
        echo "执行重装: $pkg_name-$pkg_version"
        yum -y reinstall "$rpm_path"
    else
        echo "执行安装: $pkg_name-$pkg_version"
        yum -y install "$rpm_path"
    fi
}

module_rpmbuild(){
    build_type="$1"
    type="$2"
    if [[ "$build_type" == *"$type"* ]]; then
        rpmbuild -$type -D "_topdir $PKG_PATH" "$SPEC_FILE"
        if [[ $? -ne 0 ]]; then
            log_error "错误：$type 执行失败！"
            handle_interrupt
        fi
        log_success "$type 执行成功！"
    fi
}
# 编译
module_compile() {
    # 循环提示直到用户输入非空内容或明确确认
    while grep -m1 -B9999 '^%changelog' "$SPEC_FILE" | grep -E 'anolis_release|rhel|fedora'; do
        log_warn "$SPEC_FILE 文件含有无效宏，请删除..."
        read -e -p "删除无效宏了吗？如已删除请按回车（无需删除时输入q退出）: " reply
        if [ "$reply" == "q" ]; then
            log_info "此处无需删除，退出循环！"
            break
        fi  
    done

    log_action "正在安装编译依赖..."
    if ! yum builddep -y $SPEC_FILE &> tmp.txt; then
        cat tmp.txt
        log_error "安装依赖失败"
        handle_interrupt
    fi
    rm tmp.txt
    log_success "安装编译依赖成功！"

    log_action "开始构建RPM包..."

    local build_type=$(read -e -p "请输入构建类型（ba|bp|bs）（默认：ba|bp）: " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "ba|bp")
    module_rpmbuild "$build_type" "ba"
    module_rpmbuild "$build_type" "bp"
    module_rpmbuild "$build_type" "bs"

    if [[ "$build_type" == *"ba"* ]]; then
        local man_flg=$(read -e -p "是否检查man手册路径？(y/n)(默认不检查): " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "n")
        if [[ "$man_flg" == "y" ]]; then
            module_install "$(find $RPM_DIR -name "*.rpm")"
            get_man_page_pkgs
        fi
        
        # 配置本地源
        setup_local_repo

        # 刷新yum缓存
        yum clean all >/dev/null
        yum makecache fast >/dev/null

        log_info "\n构建结果："
        for arch in noarch x86_64 sw_64; do
            local arch_dir="$RPM_DIR/$arch"
            echo -e "${BLUE}== $arch ==${NC}"
            if [ "$(ls "$arch_dir" 2>/dev/null)" ]; then
                for rpm_file_path in "$arch_dir"/*; do
                    if [[ "$man_flg" == "y" ]]; then
                        log_info "生成的rpm包路径： $rpm_file_path"
                
                        local rpm_file=$(basename $rpm_file_path)
                        local rpm_pkg=$(echo ${rpm_file%%-[0-9]*})
                        
                        if printf "%s\n" "${man_page_pkgs[@]}" | grep -q "^$rpm_pkg$"; then
                            if [ "$rpm_file_path" != "$main_pkg_rpm_file_path" ]; then
                                module_install "$rpm_file_path"
                            fi
                            log_info "$rpm_pkg 包含的 man 手册如下："
                            rpm -ql "$rpm_pkg" | grep /usr/share/man
                            en_man_num=$(rpm -ql "$rpm_pkg" | grep /usr/share/man/man | wc -l)
                            zh_man_num=$(rpm -ql "$rpm_pkg" | grep /usr/share/man/zh_CN | wc -l)
                            log_info "英文man手册数量：$en_man_num"
                            log_info "中文man手册数量：$zh_man_num"
                            if [[ "$en_man_num" -gt 0 && "$zh_man_num" -gt 0 && "$en_man_num" -eq "$zh_man_num" ]]; then
                                log_success "$rpm_pkg 包的中文man手册安装成功！"
                            else
                                log_warn "$rpm_pkg 包的中文man手册安装失败！"
                            fi
                        fi
                    else
                        echo "$rpm_file_path" 
                    fi
                done
            else
                echo "无"
            fi
            echo
        done
        # 清理
        cleanup_local_repo
    fi
}
