
module_rpmbuild(){
    build_type="$1"
    type="$2"
    if [[ "$build_type" == *"$type"* ]]; then
        rpmbuild -$type -D "_topdir $PKG_PATH" "$SPEC_FILE"
        if [[ $? -ne 0 ]]; then
            log_error "错误：执行失败！"
            handle_interrupt
        fi
        log_success "执行成功！"
    fi
}
# 编译
module_compile() {
    log_action "正在安装编译依赖..."
    if ! yum builddep -y $SPEC_FILE; then
        log_error "安装依赖失败"
        handle_interrupt
    fi
    log_success "安装编译依赖成功！"

    log_action "开始构建RPM包..."

    local build_type=$(read -e -p "请输入构建类型（ba|bp|bs）（默认：ba|bp）: " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "ba|bp")
    module_rpmbuild "$build_type" "ba"
    module_rpmbuild "$build_type" "bp"
    module_rpmbuild "$build_type" "bs"

    log_info "\n构建结果："
    for arch in noarch x86_64; do
        local arch_dir="$RPM_DIR/$arch"
        echo -e "${BLUE}== $arch ==${NC}"
        if [ "$(ls "$arch_dir" 2>/dev/null)" ]; then
            for rpm_file_path in "$arch_dir"/*; do
                echo "$rpm_file_path"
            done
        else
            echo "无"
        fi
        echo
    done
}
