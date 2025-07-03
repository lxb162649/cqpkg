# 加载配置和工具库
source "$BASE_DIR/lib/log.sh"
source "$BASE_DIR/lib/utils.sh"

# 加载功能模块
source "$BASE_DIR/modules/clone.sh"
source "$BASE_DIR/modules/patch.sh"
source "$BASE_DIR/modules/compile.sh"
source "$BASE_DIR/modules/upload.sh"
source "$BASE_DIR/modules/merge_request.sh"

# 初始化全局变量
ACTION=""
PKG_PATH=""
PKG=""

clone_flag=""

BUILD_DIR=""
SOURCES_DIR=""
SPECS_DIR=""
RPM_DIR=""

SPEC_FILE=""
NEW_SPEC_FILE=""
SPEC_FILE_BAK=""

WORK_PATH=""

src_diff_path=""
patch_path=""