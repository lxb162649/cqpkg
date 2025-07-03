# 提取的函数：计算缩进
function calculate_indent() {
    local line="$1"
    local head="$2"
    local head2="$3"
    local indent=""
    tab_count=$(echo "$line" | grep -o $'\t' | wc -l)
    
    num=$(expand -t4 $SPEC_FILE | awk "/^$head/ {match(\$0, /[[:space:]][^[:space:]]/); print RSTART}")
    needed_width=$(($num - ${#head2}))
    if [ $tab_count -eq 0 ]; then
        spaces=$needed_width
        indent=$(printf ' %.0s' $(seq 1 $spaces))
    else
        tab_count=$(( (needed_width + 3) / 4 ))
            indent=$(printf '\t%.0s' $(seq 1 $tab_count))
    fi
    echo "$indent"
}

# 提取的函数：添加patch应用命令
function add_patch_application() {
    local pattern="$1"
    
    if grep -q "$pattern" $SPEC_FILE; then
        sed -i "/$pattern/a%patch${new_patch_num} -p1" $SPEC_FILE
        echo "$(grep "$pattern" $SPEC_FILE | tail -n 1)"
        echo "添加如下"
        echo "%patch${new_patch_num} -p1"
        echo "----------"
    fi
}

# 生成补丁并修改SPEC文件
module_patch() {
    SPEC_FILE_BAK="$SPEC_FILE.bak"
    cp -f "$SPEC_FILE" "$SPEC_FILE_BAK"
    
    rpmspec -P $SPEC_FILE > $NEW_SPEC_FILE
    ############################## 生成补丁 ##############################
    log_action "正在生成补丁..."

    # 获取源码名（从BUILD目录内容推断）
    local src_name=$(ls "$BUILD_DIR" 2>/dev/null | head -n 1)
    if [ -z "$src_name" ]; then
        log_info "未找到BUILD目录下的源文件"
        # 获取源码路径
        local src_url=$(grep '^Source0:' "$NEW_SPEC_FILE" | sed 's/^Source0:\s*//')
        
        # 获取压缩源码文件名称
        local src_name_gz=$(basename "$src_url")
        if ! ls $SOURCES_DIR/$src_name_gz &> /dev/null; then
            log_action "正在下载源码: $src_name_gz ..."
            if ! wget $src_url -P $SOURCES_DIR &> /dev/null; then
                log_error "下载源码失败: $src_name_gz"
                handle_interrupt
            fi
        fi
        
        if ! yum builddep -y "$SPEC_FILE" &> tmp.txt; then
            cat tmp.txt
            log_error "安装依赖失败，请查看以上信息"
            handle_interrupt
        fi
        rm tmp.txt

        # 解压源码
        log_action "正在解压源码..."
        rpmbuild -bp -D "_topdir $PKG_PATH" "$SPEC_FILE"
    fi
    
    # 获取包名（从源码名中获取，去掉版本号）
    local pkg_name=${src_name%-*}
    local src_path=$(ls -d "$BUILD_DIR/$src_name")
    log_info "处理源码目录: $src_path"

    # 创建打补丁所需目录
    local src_diff_path="$src_path-diff"
    rm -rf "$src_diff_path"
    cp -rf $src_path $src_diff_path

    log_action "请手动修改目录: $src_diff_path ..."
    log_info "修改完成后输入补丁文件名继续"
    
    local patch_name
    while [ -z "$patch_name" ]; do
        read -e -p "请输入补丁文件名（例：cqos-func-add-chinese-man-page.patch）: " patch_name
        if [ -z "$patch_name" ]; then
            log_warn "补丁文件名不能为空!"
            log_info "请重新输入补丁文件名"
        else
            log_info "已输入补丁文件名: $patch_name"
            break
        fi
    done
    
    # 生成补丁
    cd "$BUILD_DIR"
    local patch_path="${SOURCES_DIR}/${patch_name}"
    diff -Nuar "${src_name}" "${src_name}-diff" > "$patch_path" || true
    log_info "已生成补丁: $patch_path"

    # 清理工作目录
    rm -rf $src_diff_path

    ############################## 修改 SPEC 文件 ##############################
    cd $SPECS_DIR
    log_action "正在修改 SPEC 文件: $SPEC_FILE ..."
    log_info "spec 文件修改如下："

    # 循环提示直到用户输入非空内容或明确确认
    while grep -m1 -B9999 '^%changelog' "$SPEC_FILE" | grep -E 'anolis_release|rhel|fedora'; do
        log_warn "$SPEC_FILE 文件含有无效宏，请删除..."
        read -e -p "删除无效宏了吗？如已删除请按回车（如需更改release，release不用+1）（无需删除时输入q退出）: " reply
        if [ "$reply" == "q" ]; then
            log_info "此处无需删除，退出循环！"
            break
        fi  
    done
    rm -r "$NEW_SPEC_FILE"
    rpmspec -P $SPEC_FILE > $NEW_SPEC_FILE

    # 获取spec文件中的最后一个patch行，并获取需要添加patch的数字部分
    local last_patch_head=$(grep '^Patch[0-9]\+:' $SPEC_FILE | tail -n 1 | sed 's/:.*//' || true)
    local last_patch=$(grep '^Patch[0-9]\+:' $SPEC_FILE | tail -n 1 || true)
    local new_patch_num
    if [ -z "$last_patch_head" ]; then
        new_patch_num=0
    else
        local patch_num=$(echo $last_patch_head | grep -o '[0-9]\+')
        new_patch_num=$((patch_num + 1))
    fi

    local new_patch=""
    if [ $new_patch_num == 0 ]; then
        local last_source_head=$(grep '^Source' $SPEC_FILE | tail -n 1 | cut -d':' -f1 || { log_error "$SPEC_FILE 文件内在无patch情况下未找到Source开头行！"; handle_interrupt;})
        
        local last_source=$(grep '^Source' $SPEC_FILE | tail -n 1)
        
        # 计算缩进
        indent=$(calculate_indent "$last_source" "$last_source_head" "Patch${new_patch_num}:")
        
        # 重新组合行
        new_patch="Patch${new_patch_num}:$indent${patch_name}"

        sed -i "/^$last_source_head/a$new_patch" $SPEC_FILE
        echo "$last_source"
        echo "添加如下"
        echo "$new_patch"
        echo "----------"

        # 添加 patch 应用命令
        add_patch_application "^%setup"
    else
        # 计算缩进
        indent=$(calculate_indent "$last_patch" "$last_patch_head" "Patch${new_patch_num}:")
        
        # 重新组合行
        new_patch="Patch${new_patch_num}:$indent${patch_name}"

        sed -i "/^$last_patch_head/a$new_patch" $SPEC_FILE
        echo "$last_patch"
        echo "添加如下"
        echo "$new_patch"
        echo "----------"

        # 添加 patch 应用命令
        add_patch_application "^%patch${patch_num}"
    fi

    # 提取 Epoch
    local epoch=$(grep '^Epoch:' "$NEW_SPEC_FILE" | head -n 1 | sed 's/^Epoch:\s*//')

    # 提取 Version
    local version=$(grep '^Version:' "$NEW_SPEC_FILE" | head -n 1 | sed 's/^Version:\s*//')

    # 提取 Release
    local old_release=$(grep '^Release:' "$NEW_SPEC_FILE" | head -n 1 | sed 's/^Release:\s*//; s/.cq24.*//')
    local new_release=$((old_release + 1)) 

    if [ -z "$epoch" ]; then
        version="$version-$new_release"
    else
        version="$epoch:$version-$new_release"
    fi

    # 更新 Release
    sed -i "s/^\(Release:\s*\)$old_release/\1$new_release/" "$SPEC_FILE"
    
    # 更新changelog
    local date=$(LANG=en_US.UTF-8 date '+%a %b %d %Y')
    local user_name=$(git config --global user.name)
    local user_email=$(git config --global user.email)
    local log=$(read -e -p "请输入此次更改日志（默认- Add Chinese man manual\n- Update the README.md file\n）: " \
        && [[ -n "$REPLY" ]] \
        && echo "$REPLY" \
        || echo "- Add Chinese man manual\n- Update the README.md file")
    if [ -z "$user_name" ]; then
        user_name=$(read -e -p "请设置用户名: " && [[ -n "$REPLY" ]] && echo "$REPLY")
        git config --global user.name "$user_name"
    fi
    if [ -z "$user_email" ]; then
        user_email=$(read -e -p "请设置邮箱: " && [[ -n "$REPLY" ]] && echo "$REPLY")
        git config --global user.email "$user_email"
    fi
    local changelog=$(echo "* $date $user_name <$user_email> - $version\n$log\n")

    sed -i "/^%changelog/a$changelog" "$SPEC_FILE"
    echo "%changelog"
    echo "添加如下"
    echo -e "$changelog"
    echo "----------"
    echo "SPEC 文件修改完成"
    rm -rf $MAN_TMP_PATH $NEW_SPEC_FILE
    rm -rf "$SPEC_FILE_BAK" "$MAN_TMP_PATH_BAK"
}
