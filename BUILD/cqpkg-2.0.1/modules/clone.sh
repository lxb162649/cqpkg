# 移动文件到rpmbuild目录
mv_files() {
    log_action "正在创建工作路径目录结构 $WORK_PATH ..." 
    mkdir -p "$WORK_PATH"/{SPECS,SOURCES}
    log_success "创建工作路径目录结构 $WORK_PATH 成功！"

    log_action "正在整理文件到 $WORK_PATH ..."
    
    # 移动SPEC文件
    if [[ -n $(find "$PKG_PATH" -maxdepth 1 -name "*.spec" -print -quit) ]]; then
        mv "$PKG_PATH"/*.spec "$WORK_PATH/SPECS/"
        log_success "移动SPEC文件成功！"
    else
        log_error "未找到SPEC文件！"
        handle_interrupt
    fi
    
    # 移动资源文件
    if [[ -n $(find "$PKG_PATH" -maxdepth 1 -type f ! -name ".*" -print -quit) ]]; then
        find "$PKG_PATH" -maxdepth 1 -type f ! -name ".*" -exec mv {} "$WORK_PATH/SOURCES/" \;
        log_success "移动资源文件成功！"
    else
        log_warn "未找到可移动的资源文件"
    fi
    
    # 处理.gitignore
    if [[ "$rpmbuild_flag" == "y" ]]; then
        if [[ -f "$PKG_PATH/.gitignore" ]]; then
            mv "$PKG_PATH/.gitignore" "$WORK_PATH"
            log_success "移动.gitignore文件成功！"
        fi
        rm -rf "$PKG_PATH"
        log_info "删除原克隆目录"
    else
        if [[ -d "$WORK_PATH/.git" ]]; then
            rm -rf "$WORK_PATH/.git"
            log_info "删除.git目录"
        fi
    fi

    log_success "文件移动完成！"
    return 0
}


# 生成元数据文件
generate_metadata() {
    cd "$WORK_PATH"
    local SPEC_FILE=$(ls $PKG_PATH/SPECS/*.spec)
    local NEW_SPEC_FILE="$SPEC_FILE-new"
    local use_file=""
    log_action "正在生成元数据文件 SOURCEINFO.yaml ..."
    if [[ ! -f "$SPEC_FILE" ]]; then
        log_error "未找到spec文件！"
        handle_interrupt
    fi
    if rpmspec -P "$SPEC_FILE" > "$NEW_SPEC_FILE"; then
        log_success "宏定义展开成功，生成新spec文件: $NEW_SPEC_FILE"
        use_file="$NEW_SPEC_FILE"
    else
        log_warn "宏定义展开失败，将直接使用原spec文件: $SPEC_FILE"
        use_file="$SPEC_FILE"
    fi
    local url=$(grep -E '^(URL|Url):' "$use_file" | head -n 1 | sed -E 's/^(URL|Url):\s*//')
    local license=$(grep '^License:' "$use_file" | head -n 1 | sed 's/^License:\s*//')
    rm -f "$NEW_SPEC_FILE" && log_info "删除新生成的spec文件$NEW_SPEC_FILE"
    # 确定上游仓库URL
    local upstream_url
    if [[ "$repo_type" == "a" ]]; then
        upstream_url="https://gitee.com/src-openeuler/${PKG}.git"
    else
        upstream_url="https://gitee.com/src-anolis-os/${PKG}.git"
    fi
    
    # 写入YAML
    cat <<EOF > SOURCEINFO.yaml
license:
  - ${license}
upstream:
  src: ${upstream_url}
  branch: ${branch}
origin:
  src: ${url:-"未指定上游地址"}
EOF

    log_success "元数据文件生成完成 $(pwd)/SOURCEINFO.yaml"
    log_info "查看元数据文件内容: "
    cat $(pwd)/SOURCEINFO.yaml
    return 0
}


# 克隆CQ内部仓库
clone_cq_repo() {
    # CQ内部仓库列表（按优先级排序）
    local cq_repos=(
        "http://192.168.10.152/cyos-security/public/$PKG.git"
        "http://192.168.10.152/cyos-security/protected/$PKG.git"
        "http://192.168.10.152/cyos-security/private/$PKG.git"
        "http://192.168.10.152/cyos-security/trash/$PKG.git"
        "http://192.168.10.152/cyos-security/iso/$PKG.git"
        "http://192.168.10.152/cyos-security/$PKG.git"
        "http://192.168.10.152/cyos-security/toolkits/$PKG.git"
        "http://192.168.10.152/cyos-security/transition/python3.11/$PKG.git"
        "http://192.168.10.152/cyos-security/transition/deb_to_rpm/$PKG.git"
        "http://192.168.10.152/cyos-security/transition/xfce/$PKG.git"
        "http://192.168.10.152/cyos-security/transition/$PKG.git"
        "http://192.168.10.152/lixuebing/$PKG.git"
    )
    
    log_action "开始克隆项目到: $PKG_PATH..."
    
    local repo_found=false
    for repo in "${cq_repos[@]}"; do
        # 检查仓库是否存在
        if git ls-remote $repo &>/dev/null; then
            git clone -b "$branch" "$repo"
            repo_found=true
                break
            fi
    done
    
    if ! $repo_found; then
        log_error "未找到任何可用的仓库"
        handle_interrupt
    fi
    
    return 0
}

module_clone() {
    WORK_PATH="$PKG_PATH"  # 默认工作路径为PKG_PATH
    local cq_flag=false  # CQ内部仓库标志
    # -e 启用输入编辑功能、-r 禁用反斜杠转义、-s 隐藏输入内容
    local repo_type=$(read -e -p "请选择仓库类型（a=欧拉, b=龙蜥, 其他=CQ内部仓库）: " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "c")
    case "$repo_type" in
        a)
            log_info "使用仓库类型: 欧拉"
            ;;
        b)
            log_info "使用仓库类型: 龙蜥"
            ;;
        *)
            log_info "使用仓库类型: CQ内部仓库"
            cq_flag=true
            ;;
    esac

    local branch=$(read -e -p "请输入克隆分支（默认master）: " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "master")
    log_info "使用分支: $branch"
    
    # 是否创建rpmbuild目录
    local rpmbuild_flag=$(read -e -p "是否将代码放入$HOME/rpmbuild目录（输入y放入此目录，默认放到 $PKG_PATH 目录）: " && [[ -n "$REPLY" ]] && echo "$REPLY")
    
    # 设置工作路径
    if [[ "$rpmbuild_flag" == "y" ]]; then
        WORK_PATH="$HOME/rpmbuild"  # 放入$HOME/rpmbuild目录
    fi

    log_info "工作路径设置为: $WORK_PATH"

    if [[ -d "$PKG_PATH" ]]; then
        rm -rf "$PKG_PATH"  # 删除原有的PKG_PATH目录
        log_info "已删除原有的 $PKG_PATH 目录"
    fi

    if [[ -d "$WORK_PATH" ]]; then
        rm -rf "$WORK_PATH"
        log_info "已清理旧工作路径 $WORK_PATH"
    fi
    
    # 根据仓库类型克隆
    case "$repo_type" in
        a)
            gitee_authentication
            local upstream_url="https://gitee.com/src-openeuler/${PKG}.git"
            if ! git clone -b "$branch" "$upstream_url"; then
                log_error "${PKG}仓库克隆失败！"
                handle_interrupt
            fi
            log_success "${PKG}克隆成功！"
            ;;
        b)
            gitee_authentication
            local upstream_url="https://gitee.com/src-anolis-os/${PKG}.git"
            if ! git clone -b "$branch" "$upstream_url"; then
                log_error "${PKG}克隆失败！"
                handle_interrupt
            fi
            log_success "${PKG}克隆成功！"
            ;;
        *)
            gitlab_authentication
            clone_cq_repo
            log_success "${PKG}克隆成功！"
            
            if [[ "$rpmbuild_flag" == "y" ]]; then
                log_action "正在将 $PKG 复制到工作目录 $WORK_PATH ..."
                cp -rf "$PKG_PATH" "$WORK_PATH"
                log_success "成功将 $PKG 复制到工作目录 $WORK_PATH ！"
            fi
            ;;
    esac
    
    # 检查是否需要创建.gitignore
    if [[ ! -f "$PKG_PATH/.gitignore" ]] && [[ -n $(find "$PKG_PATH" -name '*.spec' &>/dev/null) ]]; then
        log_action "正在创建.gitignore文件..."
    
        cat > "$PKG_PATH/.gitignore" << EOF
#rpm
RPMS
SRPMS
BUILDROOT
#vscode
.vscode 
EOF
    
        if [[ $? -eq 0 ]]; then
            log_success ".gitignore文件创建成功！"
        else
            log_error ".gitignore文件创建失败！"
            handle_interrupt
        fi
    fi
    if $cq_flag; then
        log_success "操作完成！RPM构建环境已配置到 $WORK_PATH"
        exit 0
    fi
    # 移动文件
    mv_files

    # 生成元数据
    generate_metadata
    
    log_info "操作完成！RPM构建环境已配置到 $WORK_PATH"
}   
