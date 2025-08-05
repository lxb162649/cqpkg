show_help() {
    echo -e "${BLUE}CQ软件包管理${NC}"
    echo
    echo -e "${YELLOW}功能说明：${NC}"
    echo -e "  ${GREEN}•${NC} 管理CQ软件包，包括克隆、打补丁、编译、上传、重新上传和提交合并请求"
    echo -e "  ${GREEN}•${NC} 支持以下操作模式："
    echo "    clone:            克隆代码仓库"
    echo "    extract:          从系统中提取并解压man文件"
    echo "    translator:       翻译man手册"
    echo "    patch:            生成补丁并修改SPEC文件"
    echo "    compile:          编译RPM包"
    echo "    upload:           上传代码"
    echo "    reupload:         重新上传代码（返回上次提交）"
    echo "    merge_request:    提交合并请求"
    echo
    echo -e "${YELLOW}使用语法：${NC}"
    echo "  $(basename "$0") [选项] <PKG_PATH>"
    echo
    echo -e "${YELLOW}选项：${NC}"
    echo -e "  ${GREEN}-cl, --clone${NC}            克隆代码仓库"
    echo -e "  ${GREEN}-e,  --extract${NC}          提取并解压man文件"
    echo -e "  ${GREEN}-tr, --translator${NC}       翻译man手册"
    echo -e "  ${GREEN}-p,  --patch${NC}            生成补丁并修改SPEC文件"
    echo -e "  ${GREEN}-co, --compile${NC}          编译RPM包"
    echo -e "  ${GREEN}-u,  --upload${NC}           上传代码"
    echo -e "  ${GREEN}-reu,--reupload${NC}         重新上传代码（返回上次提交）"
    echo -e "  ${GREEN}-mr, --merge_request${NC}    提交合并请求"
    echo -e "  ${GREEN}-h,  --help${NC}             显示此帮助信息"
    echo
    echo -e "${YELLOW}示例:${NC}${RED}${NC}"
    echo "  步骤1:  $(basename "$0") package -cl    # 克隆包"
    echo "  步骤2:  $(basename "$0") package -e     # 提取man文件"
    echo "  步骤3:  $(basename "$0") package -tr    # 翻译man文件"
    echo "  步骤4:  $(basename "$0") package -p     # 生成补丁并修改SPEC"
    echo "  步骤5:  $(basename "$0") package -co    # 编译RPM包"
    echo "  步骤6.1:$(basename "$0") package -u     # 上传结果"
    echo "  步骤6.2:$(basename "$0") package -reu   # 重新上传结果（可选）"
    echo "  步骤7:  $(basename "$0") package -mr    # 提交合并请求"
    exit 0
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -cl|--clone)
                ACTION="clone"
                ;;
            -e|--extract)
                ACTION="extract"
                ;;
            -tr|--translator)
                ACTION="translator"
                ;;
            -p|--patch)
                ACTION="patch"
                ;;
            -co|--compile)
                ACTION="compile"
                ;;
            -u|--upload)
                ACTION="upload"
                ;;
            -reu|--reupload)
                ACTION="reupload"
                ;;
            -mr|--merge_request)
                ACTION="merge_request"
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *) 
                # 如果参数不是选项，则认为是PKG_PATH
                if [[ -z "$PKG_PATH" ]]; then
                    if ! PKG_PATH="$(realpath -e "$1" 2>/dev/null)"; then
                        if [ "$1" == "$(basename $1)" ]; then
                            PKG_PATH=$(pwd)/$1
                            clone_flag=1
                            log_action "当前目录不存在包 $1，ACTION 参数失效，即将克隆 $1 到 $PKG_PATH..." 
                        else
                            log_error "错误: 目录 '$1' 不存在"
                            exit 1
                        fi
                    fi
                else
                    log_error "错误: 重复的路径参数 '$1'"
                    exit 1
                fi
                ;;
        esac
        shift
    done

    # 检查是否提供了PKG_PATH
    if [[ -z "$PKG_PATH" ]]; then
        log_error "请提供包路径"
        exit 1
    fi
}

gitlab_authentication() {
    if [[ -z "$HOME/.git-credentials" ]]; then
        touch "$HOME/.git-credentials"
    fi
    if ! grep -q "192.168.10.152" "$HOME/.git-credentials"; then
        log_warn "未进行身份验证，请验证"
        gitlab_user=$(read -e -p "请输入gitlab用户名: " reply)
        gitlab_password=$(read -e -p "请输入gitlab密码: " reply)
        echo "https://$gitlab_user:$gitlab_password@192.168.10.152" >> "$HOME/.git-credentials"
    fi
    git config --global credential.helper store
}

gitee_authentication() {
    if [[ -z "$HOME/.git-credentials" ]]; then
        touch "$HOME/.git-credentials"
    fi
    if ! grep -q "gitee" "$HOME/.git-credentials"; then
        log_warn "未进行身份验证，请验证"
        gitee_user=$(read -e -p "请输入gitee用户名: " reply)
        gitee_password=$(read -e -p "请输入gitee密码: " reply)
        echo "https://$gitee_user:$gitee_password@192.168.10.152" >> "$HOME/.git-credentials"
    fi
    git config --global credential.helper store
}

# 从%files行提取包名
extract_pkg() {
    local files_str="$1"
    local pkg_name=""
    
    if [[ -z "$files_str" ]]; then
        return 0
    fi

    # 处理带-n参数的包名（如%files -n subpackage）
    if [[ $files_str =~ -n[[:space:]]+([^[:space:]]+) ]]; then
        pkg_name="${BASH_REMATCH[1]}"
    else
        # 提取第二个字段并处理前缀（默认使用主包名）
        local base_name=$(echo "$files_str" | awk '{print $2}' | sed -E 's/-f.*//')
        pkg_name="${base_name:+"$main_pkg-"}${base_name:-"$main_pkg"}"
    fi

    echo "$pkg_name"
}

# 检查SPEC文件中含有man手册的包
get_man_page_pkgs() {
    log_action "正在检查 $PKG 及其子包是否包含 man 手册..."
    
    # 展开 spec 文件中的宏定义（目的：方便获取子包名）
    rpmspec -P $SPEC_FILE > $NEW_SPEC_FILE

    local main_pkg=("$(grep '^Name:' "$NEW_SPEC_FILE" | sed 's/^Name:\s*//')")

    # spec 文件中 %files 行信息（用于查询含有man手册的包）
    local files_messages=()
    readarray -t files_messages < <(grep '^%files' "$NEW_SPEC_FILE")

    local section_count=${#files_messages[@]}

    # 遍历每个%files区域（除了最后一个）
    for ((i=0; i<${#files_messages[@]}; i++)); do
        local current="${files_messages[$i]}"

        local next=""
        if [[ $i -lt $((section_count-1)) ]]; then
            next="${files_messages[$i+1]}"
        else
            next="^%changelog"
        fi

        local result=$(awk -v current_pattern="$current" -v next_pattern="$next" '
            $0 == current_pattern { flag = 1; next }
            $0 == next_pattern { flag = 0; exit }
            flag && $0 ~ /\/usr\/share\/man\// { print; exit }
        ' "$NEW_SPEC_FILE")

        if [[ -n "$result" ]]; then
            man_page_pkgs+=("$(extract_pkg "${current}")")
        fi
    done

    if [[ ${#man_page_pkgs[@]} -eq 0 ]]; then
        rm -f "$NEW_SPEC_FILE"
        log_error "此包及其子包不包含man手册！"
        handle_interrupt
    fi
    rm -f "$NEW_SPEC_FILE"
}

# 中断处理
handle_interrupt() {
    case "$ACTION" in
        clone)
            log_action "\n收到中断信号，正在结束 clone 操作..."
            [ -d "$PKG_PATH" ] && rm -rf "$PKG_PATH" && log_info "已清理包路径：$PKG_PATH"
            ;;
        extract)
            log_action "\n收到中断信号，正在结束 extract 操作..."
            [ -f "$NEW_SPEC_FILE" ] && rm -rf "$NEW_SPEC_FILE" && log_info "已清理展开宏的spec文件：$NEW_SPEC_FILE"
            [ -d "$MAN_TMP_PATH" ] && rm -rf "$MAN_TMP_PATH" && log_info "已清理man手册路径：$MAN_TMP_PATH"
            ;;
        translator)
            log_action "\n收到中断信号，正在结束 translator 操作..."
            if [ -n "$translating_file" ] && [ -f "$translating_file" ]; then
                rm -f "$translating_file"
                log_info "已删除临时翻译文件: $translating_file"
            fi
            log_error "翻译任务已中断！"
            ;;
        patch)
            log_action "\n收到中断信号，正在结束 patch 操作..."
            [ -f "$NEW_SPEC_FILE" ] && rm -rf "$NEW_SPEC_FILE" && log_info "已清理展开宏的spec文件：$NEW_SPEC_FILE"
            [ -d "$src_diff_path" ] && rm -rf "$src_diff_path" && log_info "已清理用于生成patch的源码包路径：$src_diff_path"
            [ -f "$patch_path" ] && rm -rf "$patch_path" && log_info "已清理patch文件：$patch_path"
            rm -f "$SPEC_FILE"
            mv -f "$SPEC_FILE_BAK" "$SPEC_FILE" && log_info "已恢复spec文件：$SPEC_FILE"
            if [ -d "$MAN_TMP_PATH" ]; then
                rm -rf "$MAN_TMP_PATH"
            fi
            mv -f "$MAN_TMP_PATH_BAK" "$MAN_TMP_PATH" && log_info "已恢复man手册路径：$MAN_TMP_PATH"
            ;;
        compile)
            log_action "\n收到中断信号，正在结束 compile 操作..."
            ;;
        upload)
            log_action "\n收到中断信号，正在结束 upload 操作..."
            ;;
        reupload)
            log_action "\n收到中断信号，正在结束 reupload 操作..."
            ;;
        merge_request)
            log_action "\n收到中断信号，正在结束 merge_request 操作..."
            ;;
    esac
    exit 1
}
