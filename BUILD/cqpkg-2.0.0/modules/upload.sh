# 上传代码到仓库
module_upload() {
    cd $PKG_PATH

    local branch=$(read -e -p "请输入要上传的分支（默认：dev）: " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "dev")

    local commit_msg_init='"更新(man): 添加中文手册，更新README.md"'
    local commit_msg=$(read -e -p "请输入要提交信息（默认：$commit_msg_init）:  " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "更新(man): 添加中文手册，更新README.md")

    # 建立分支
    git branch -M $branch

    # 将所有文件进行打包至预发区并说明提交信息
    log_action "准备提交代码..."
    git add -A
    git commit -m "$commit_msg"

    # 上传/提交到 mugen 的 $branch 分支中
    log_action "正在推送代码到远程仓库..."
    git push -uf origin $branch

    # 执行备份（仅当存在RPM文件时）
    if [ "$(ls -A RPMS 2>/dev/null)" ]; then
        log_action "创建备份到 ../success/RPMS"
        local backup_dir="../success/RPMS"
        mkdir -p $backup_dir/{noarch,x86_64}
        
        # 备份noarch架构包
        if ls -1 $PKG_PATH/RPMS/noarch/*.rpm &> /dev/null; then
            cp -v $PKG_PATH/RPMS/noarch/*.rpm "$backup_dir/noarch/"
        fi
        
        # 备份x86_64架构包
        if ls -1 $PKG_PATH/RPMS/x86_64/*.rpm &> /dev/null; then
            cp -v $PKG_PATH/RPMS/x86_64/*.rpm "$backup_dir/x86_64/"
        fi
    else
        log_warn "警告：未找到RPM文件，跳过备份"
    fi

    log_success "操作完成！代码已推送至 $branch 分支"
}
