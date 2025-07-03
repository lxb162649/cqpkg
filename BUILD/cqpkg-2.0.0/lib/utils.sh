show_help() {
    echo -e "${BLUE}CQ软件包管理${NC}"
    echo
    echo -e "${YELLOW}功能说明：${NC}"
    echo -e "  ${GREEN}•${NC} 管理CQ软件包，包括克隆、打补丁、编译、上传、重新上传和提交合并请求"
    echo -e "  ${GREEN}•${NC} 支持以下操作模式："
    echo "    clone:            克隆代码仓库"
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
    echo -e "  ${GREEN}-p,  --patch${NC}            生成补丁并修改SPEC文件"
    echo -e "  ${GREEN}-co, --compile${NC}          编译RPM包"
    echo -e "  ${GREEN}-u,  --upload${NC}           上传代码"
    echo -e "  ${GREEN}-reu,--reupload${NC}         重新上传代码（返回上次提交）"
    echo -e "  ${GREEN}-mr, --merge_request${NC}    提交合并请求"
    echo -e "  ${GREEN}-h,  --help${NC}             显示此帮助信息"
    echo
    echo -e "${YELLOW}示例:${NC}"
    echo "  $(basename "$0") package -cl    # 克隆包"
    echo "  $(basename "$0") package -p     # 生成补丁并修改SPEC"
    echo "  $(basename "$0") package -co    # 编译RPM包"
    echo "  $(basename "$0") package -u     # 上传结果"
    echo "  $(basename "$0") package -reu   # 重新上传结果（可选）"
    echo "  $(basename "$0") package -mr    # 提交合并请求"
    exit 0
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -cl|--clone)
                ACTION="clone"
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

# 中断处理
handle_interrupt() {
    case "$ACTION" in
        clone)
            log_action "\n收到中断信号，正在结束 clone 操作..."
            [ -d "$PKG_PATH" ] && rm -rf "$PKG_PATH" && log_info "已清理包路径：$PKG_PATH"
            [ -d "$WORK_PATH" ] && rm -rf "$WORK_PATH" && log_info "已清理工作路径：$WORK_PATH"
            ;;
        patch)
            log_action "\n收到中断信号，正在结束 patch 操作..."
            [ -f "$NEW_SPEC_FILE" ] && rm -rf "$NEW_SPEC_FILE" && log_info "已清理展开宏的spec文件：$NEW_SPEC_FILE"
            [ -d "$src_diff_path" ] && rm -rf "$src_diff_path" && log_info "已清理用于生成patch的源码包路径：$src_diff_path"
            [ -f "$patch_path" ] && rm -rf "$patch_path" && log_info "已清理patch文件：$patch_path"
            rm -f "$SPEC_FILE"
            mv -f "$SPEC_FILE_BAK" "$SPEC_FILE" && log_info "已恢复spec文件：$SPEC_FILE"
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
