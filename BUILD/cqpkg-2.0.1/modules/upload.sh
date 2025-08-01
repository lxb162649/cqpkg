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

    log_success "操作完成！代码已推送至 $branch 分支"
}
