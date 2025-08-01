# 提取并解压man文件
module_extract() {
    get_man_page_pkgs

    for man_page_pkg in "${man_page_pkgs[@]}"; do
        log_action "正在安装 $man_page_pkg 包..."
        if dnf install -y $man_page_pkg &> tmp.txt; then
            log_info "包 $man_page_pkg 安装成功"
        else
            log_error "安装 $man_page_pkg 失败，查看失败原因如下："
            cat tmp.txt
            handle_interrupt
        fi
        rm -f tmp.txt
        readarray -t tmp_paths < <(rpm -ql "$man_page_pkg" 2>/dev/null | grep -E "/usr/share/man")

        man_file_paths+=("${tmp_paths[@]}")
    done

    local success_counter=0
    local fail_counter=0
    local total_files=0
    # 创建man手册临时存放路径
    mkdir -p "$MAN_TMP_PATH"
    for man_file_path in "${man_file_paths[@]}"; do
        # 解压模式
        local man_file_gz=$(basename "$man_file_path")
        local man_file="${man_file_gz%.gz}"
        if [[ "$man_file_path" == *zh_CN* ]]; then
            log_warn "$man_file_path 是中文手册！"
            log_info "解压此中文手册到 $MAN_TMP_PATH 目录，删除已存在同名英文man手册，下次遇到同名英文man手册不再解压，不再翻译 $MAN_TMP_PATH/$man_file"
            
            if [[ -f "$MAN_TMP_PATH/$man_file" ]]; then
                rm -f "$MAN_TMP_PATH/$man_file" && log_info "已删除 $MAN_TMP_PATH/$man_file"
                ((total_files--))
                ((success_counter--))
            fi
            mkdir -p "$MAN_TMP_PATH/zh_CN"
            touch "$MAN_TMP_PATH/zh_CN/$man_file.success"
        fi
        log_action "正在处理 $man_file_path..."
        if [[ -f "$MAN_TMP_PATH/zh_CN/$man_file.success" ]] && ! ls $man_file_path | grep zh_CN &> /dev/null; then
            log_warn "警告: 已解压中文手册 $MAN_TMP_PATH/$man_file，跳过解压！"
            continue
        fi
        # 复制到 MAN_TMP_PATH 目录
        if ! cp "$man_file_path" "$MAN_TMP_PATH"; then
            log_warn "警告: 无法复制 $man_file_path 到 $MAN_TMP_PATH"
            continue
        fi
        
        # 解压文件
        cd "$MAN_TMP_PATH" && gunzip "$man_file_gz" &> /dev/null
        if [[ $? -eq 0 ]]; then
            ((success_counter++))
            log_info "✓ 解压完成:  $MAN_TMP_PATH/$man_file"
        else
            ((fail_counter++))
            log_warn "× 解压失败:  $MAN_TMP_PATH/$man_file_gz"
        fi
        ((total_files++))
    done
    log_info "解压目录: $MAN_TMP_PATH"
    log_info "成功：$success_counter 个"
    log_info "失败：$fail_counter 个"
    log_info "总计：$total_files 个"
}
