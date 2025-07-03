# 创建合并请求
module_merge_request() {
    GITLAB_URL="http://192.168.10.152"

    # 泓宇的id
    ASSIGNEE_ID_Init=50
    ASSIGNEE_ID=$(read -e -p "请输入指派人ID（默认：$ASSIGNEE_ID_Init）: " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "50")

    cd "$PKG_PATH"
    # 获取当前Git仓库的远程URL并处理为目标格式
    PROJECT_PATH_FORMAT=$(git remote get-url origin | awk -F'/' '{
        # 提取域名后的所有路径部分
        for(i=4; i<=NF; i++) {
            path = (path ? path "/" $i : $i)
        }
        # 移除 .git 后缀
        gsub(/\.git$/, "", path)
        # 将 / 替换为 %2F
        gsub(/\//, "%2F", path)
        print path
    }')
    
    if [ -z "$GITLAB_PRIVATE_TOKEN" ]; then
        GITLAB_PRIVATE_TOKEN=$(read -e -p "请输入 gitlab 访问令牌:  " && [[ -n "$REPLY" ]] && echo "$REPLY")
        echo "export GITLAB_PRIVATE_TOKEN='$GITLAB_PRIVATE_TOKEN'" >> ~/.bashrc
        source ~/.bashrc
    fi

    API_ENDPOINT="${GITLAB_URL}/api/v4/projects/${PROJECT_PATH_FORMAT}/merge_requests"

    # MR配置
    SOURCE_BRANCH=$(git branch --show-current)
    TARGET_BRANCH="master"

    MR_TITLE_Init='"更新(man): 添加中文手册，更新README.md"'
    MR_TITLE=$(read -e -p "请输入合并请求标题（默认：$MR_TITLE_Init）:  " && [[ -n "$REPLY" ]] && echo "$REPLY" || echo "更新(man): 添加中文手册，更新README.md")

    PROJECT_PATH=$(git remote get-url origin | sed 's/\.git$//')
    log_info "==> 调试信息 <=="
    log_info "API端点: ${API_ENDPOINT}"
    log_info "项目路径: ${PROJECT_PATH}"
    log_info "源分支: ${SOURCE_BRANCH}，目标分支: ${TARGET_BRANCH}"
    log_info "================="

    # 创建临时文件存储响应
    TMP_RESPONSE=$(mktemp)

    # 发送API请求（使用JSON格式参数，适配API要求）
    log_action "正在创建合并请求..."
    MR_RESPONSE=$(curl -s --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{
        \"source_branch\": \"${SOURCE_BRANCH}\",
        \"target_branch\": \"${TARGET_BRANCH}\",
        \"title\": \"${MR_TITLE}\",
        \"assignee_ids\": [${ASSIGNEE_ID}]
    }" \
    "${API_ENDPOINT}" | tee "$TMP_RESPONSE")

    # 检查响应结果
    if grep -q "\"id\":" "$TMP_RESPONSE"; then
        log_success "合并请求创建成功!"
        
        # 尝试使用jq解析web_url
        if ! command -v jq &>/dev/null; then
            yum install -y jq
        fi
        MR_WEB_URL=$(jq -r '.web_url' "$TMP_RESPONSE")
        log_info "MR URL: ${MR_WEB_URL}"
    else
        grep -o '"message":"[^"]*"' "$TMP_RESPONSE" | cut -d'"' -f4 || cat "$TMP_RESPONSE"
        log_error "创建失败，错误详情如上"
    fi

    # 清理临时文件
    rm -f "$TMP_RESPONSE"
}