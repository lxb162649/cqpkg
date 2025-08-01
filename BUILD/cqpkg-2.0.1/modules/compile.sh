module_install() {
    local rpm_file_path=$1
    local rpm_file=$(basename $rpm_file_path)
    local rpm_pkg=$(echo ${rpm_file%%-[0-9]*})
    local local_rpm_file=$(rpm -q "$rpm_pkg")
    local install_type=""

    if [ "$rpm_file" == "$(echo "$local_rpm_file.rpm")" ]; then
        install_type="reinstall"
        log_action "✓ $rpm_pkg 已安装,正在重新安装..."
    else
        install_type="install"
        log_action "✗ $rpm_pkg 未安装，正在安装..."
    fi
    if ! yum $install_type -y "$rpm_file_path" &> tmp.txt; then
        cat tmp.txt
        log_warn "$rpm_pkg 安装失败!"
    else
        log_success "$rpm_pkg 安装成功!"
    fi
    rm tmp.txt
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
    fi
}
