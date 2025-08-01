translator() {
    local input_path="$1"
    local input_file=$(basename "$input_path")
    local output_catalogue="$2"
    local chunk_num=1
    local line_count=0
    local -a lines  # 声明局部数组

    # 创建临时文件
    while IFS= read -r line; do
        lines[$line_count]="$line"
        ((line_count++))

        if [ "$line_count" -eq "300" ]; then
            local output_file="$output_catalogue/$input_file.tmp${chunk_num}"
            # 检查是否已存在临时文件，避免重复翻译
            if [ -f "$output_catalogue/$input_file.tmp$(( chunk_num + 1 ))" ]; then
                continue
            fi
            printf "%s\n" "${lines[@]}" > "$output_file"
            man-translator "$output_file" --overwrite || return 1
            unset lines
            declare -a lines
            line_count=0
            ((chunk_num++))
        fi
    done < "$input_path"

    # 处理剩余的行
    if [ "$line_count" -gt 0 ]; then
        local output_file="$output_catalogue/$input_file.tmp${chunk_num}"
        printf "%s\n" "${lines[@]}" > "$output_file"
        man-translator "$output_file" --overwrite || return 1
    fi

    local output_file="$input_path"
    local chunk_num=1

    # 创建或清空输出文件
    > "$output_file"

    # 按顺序合并所有临时文件
    while [ -f "$output_catalogue/$input_file.tmp${chunk_num}" ]; do
        local chunk="$output_catalogue/$input_file.tmp${chunk_num}"
        cat "$chunk" >> "$output_file"
        rm -f "$output_catalogue/$input_file.tmp${chunk_num}"
        ((chunk_num++))
    done
    
    return 0
}

# 翻译man手册
module_translator() {
    # 检查并安装依赖工具
    if ! command -v man-translator >/dev/null 2>&1; then
        log_warn "未找到 man-translator 命令！"
        log_action "正在安装 man-translator 命令..."
        
        if ! command -v uv >/dev/null 2>&1; then
            log_warn "未找到 uv 命令！"
            log_action "正在安装 uv 命令..."
            
            # 尝试多种方式安装uv
            if ! sh -c "$(curl --proto '=https' --tlsv1.3 -sSf https://astral.sh/uv/install.sh)"; then
                if ! sh -c "$(curl -LsSf https://astral.sh/uv/install.sh)"; then
                    log_error "安装 uv 命令失败"
                    return 1
                fi
            fi
            log_success "安装 uv 命令成功"
        fi
        
        # 安装 man-translator 并检查结果
        if ! uv tool install git+http://192.168.10.152/lixuebing/man-translator; then
            log_error "安装 man-translator 命令失败"
            return 1
        fi
        log_success "安装 man-translator 命令成功"
    fi

    # 获取源目录下的所有文件（不包含子目录）
    local list=$(find "$MAN_TMP_PATH" -maxdepth 1 -type f -print0 | tr '\0' '\n')
    local total_files=$(echo "$list" | wc -l)
    local MAN_TRANSLATOR_TMP_PATH="$MAN_TMP_PATH/zh_CN"
    mkdir -p "$MAN_TRANSLATOR_TMP_PATH"
    log_info "找到 $total_files 个文件需要翻译"

    # 初始化计数器
    local file_counter=0
    local success_counter=0
    local fail_counter=0

    # 读取 $list 文件中的每一行并翻译对应的文件
    while IFS= read -r file_path; do
        ((file_counter++))
        # 使用更高效的文件检查和正则匹配
        file=$(basename "$file_path")
        translating_file="$MAN_TRANSLATOR_TMP_PATH/$file.translating"
        success_file="$MAN_TRANSLATOR_TMP_PATH/$file.success"
        
        if [ -f "$file_path" ] && [ ! -f "$success_file" ] && [ ! -f "$translating_file" ]; then
            log_action "[$file_counter/$total_files] 正在翻译： $file_path ..." && touch "$translating_file"
            translator "$file_path" "$MAN_TRANSLATOR_TMP_PATH"
            if [ $? -eq 0 ]; then
                ((success_counter++))
                touch "$success_file" && rm -f "$translating_file"
                log_success "[$file_counter/$total_files] 文件 $file_path 翻译成功"
            else
                ((fail_counter++))
                log_warn "[$file_counter/$total_files] 文件 $file_path 翻译失败"
                rm -f "$translating_file"  # 删除临时翻译文件
                continue  # 跳过后续处理
            fi
        else
            # 使用更清晰的条件判断
            if [ ! -f "$file_path" ]; then
                ((fail_counter++))
                log_info "[$file_counter/$total_files] 文件 $file_path 不存在，跳过"
            elif [ -f "$translating_file" ]; then
                ((fail_counter++))
                log_info "[$file_counter/$total_files] 文件 $file_path 正在翻译，跳过"
            else
                ((success_counter++))
                log_info "[$file_counter/$total_files] 文件 $file_path 已翻译，跳过"
            fi
        fi
    done <<< "$list"
    
    # 检查所有文件是否都已翻译
    log_action "检查所有文件是否都已翻译..."
    local all_success=true
    while IFS= read -r file_path; do
        file=$(basename "$file_path")
        success_file="$MAN_TRANSLATOR_TMP_PATH/$file.success"
        if [ ! -f "$success_file" ]; then
            log_error "存在文件还未翻译成功: $file_path"
            all_success=false
        fi
    done <<< "$list"

    if [ "$all_success" = true ]; then
        log_success "所有文件都已翻译成功！"
        log_action "正在删除翻译临时目录..."
        rm -rf "$MAN_TRANSLATOR_TMP_PATH"
        log_success "已删除翻译临时目录！"
    else
        log_error "翻译过程中存在失败的文件！"
    fi

    # 输出汇总结果
    log_success "翻译完成！"
    log_info "成功：$success_counter 个"
    log_info "失败：$fail_counter 个"
    log_info "总计：$total_files 个"
}
