# 临时yum源配置文件
local_repo="/etc/yum.repos.d/local_kyotocabinet.repo"

# 配置本地yum源（包含所有子目录）
setup_local_repo() {
    # 创建repo
    createrepo "$RPM_DIR" &>/dev/null && log_success "已创建仓库元数据" || log_error "创建仓库元数据失败"
    
    # 创建repo文件
    cat > "$local_repo" <<EOF
[local-kyotocabinet]
name=Local Kyotocabinet RPMs
baseurl=file:///$RPM_DIR
enabled=1
gpgcheck=0
priority=1
EOF
    log_info "已配置本地RPM源，包含目录: $RPM_DIR"
    # 刷新yum缓存
    yum clean all &>/dev/null
    yum makecache &>/dev/null
    log_info "已刷新yum缓存"
}

# 清理临时yum源
cleanup_local_repo() {
    if [ -d "$RPM_DIR/repodata" ]; then
        rm -rf "$RPM_DIR/repodata"
        log_info "已清理仓库元数据"
    fi
    if [ -f "$local_repo" ]; then
        rm -f "$local_repo"
        log_info "已清理本地源配置"
        # 刷新yum缓存
        yum clean all &>/dev/null
        yum makecache &>/dev/null
        log_info "已刷新yum缓存"
    fi
}

# rpm已安装则重装，未安装则安装
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
    if rpm -q "$pkg_name-$pkg_version" --quiet; then
        log_action "执行重装: $pkg_name-$pkg_version"
        yum -y reinstall "$pkg_name" &>/dev/null && log_success "已重装: $pkg_name-$pkg_version" || log_error "重装失败: $pkg_name-$pkg_version"
    else
        log_action "执行安装: $pkg_name-$pkg_version"
        yum -y install "$pkg_name" &>/dev/null && log_success "已安装: $pkg_name-$pkg_version" || log_error "安装失败: $pkg_name-$pkg_version"
    fi
}

# 根据参数选项执行rpmbuild（ba|bp|bs）
module_rpmbuild(){
    build_type="$1"

    # 以|为分隔符分割字符串到数组 build_type
    IFS='|' read -ra types <<< "$build_type"

    # 定义标记变量，用于记录是否存在"bp"
    has_bp=0

    # 循环遍历数组元素
    for type in "${types[@]}"; do
        # 检查当前元素是否为"bp"
        if [ "$type" = "bp" ]; then
            has_bp=1
            continue
        fi
        rpmbuild -$type -D "_topdir $PKG_PATH" "$SPEC_FILE"
        if [[ $? -ne 0 ]]; then
            log_error "错误：$type 执行失败！"
            handle_interrupt
        fi
        log_success "$type 执行成功！"
    done

    # 如果存在"bp"，则最后执行bp
    if [ $has_bp -eq 1 ]; then
        rpmbuild -bp -D "_topdir $PKG_PATH" "$SPEC_FILE"
        if [[ $? -ne 0 ]]; then
            log_error "错误：bp 执行失败！"
            handle_interrupt
        fi
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

    if [ $(whoami) == "root" ]; then
        log_action "正在安装编译依赖..."
        if ! yum builddep -y $SPEC_FILE; then
            log_error "安装依赖失败"
            handle_interrupt
        fi
        log_success "安装编译依赖成功！"
    else
        log_warn "非root用户无法安装编译依赖，跳过"
    fi

    log_action "开始构建RPM包..."

    local build_type=$(read -e -p "请输入构建类型（ba|bp|bs）（默认：ba|bp）: " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "ba|bp")
    rm -rf "$RPM_DIR"
    module_rpmbuild "$build_type"

    if [[ "$build_type" == *"ba"* ]]; then
        local man_flg=$(read -e -p "是否检查man手册路径？(y/n)(默认不检查): " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "n")
        if [[ "$man_flg" == "y" ]]; then
            get_man_page_pkgs
            # 配置本地源
            setup_local_repo
        fi
        
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
                            module_install "$rpm_file_path"
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
