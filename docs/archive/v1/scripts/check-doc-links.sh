#!/bin/bash

##############################################################################
# 文档链接有效性检查脚本
#
# 用途：检查 Markdown 文档中的相对链接是否有效
# 使用：./scripts/check-doc-links.sh
#
# 作者：Claude Code
# 版本：v1.0.0
# 更新：2026-01-21
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计变量
total_links=0
invalid_links=0

# 打印函数
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "🔗 检查文档链接有效性"
echo ""

# 检查函数
check_links_in_file() {
    local file=$1

    # 提取文档中的相对链接（Markdown 格式）
    # 匹配 [text](path) 格式，排除 http/https 链接
    local links=$(grep -oE '\[.*\]\(([^)]+)\)' "$file" 2>/dev/null | \
                 grep -oE '\(([^)]+)\)' | \
                 tr -d '()' | \
                 grep -vE '^https?://' | \
                 grep -vE '^mailto:' | \
                 grep -E '^\.\./|^\./|^[^/]')

    if [ -z "$links" ]; then
        return
    fi

    local file_dir=$(dirname "$file")

    for link in $links; do
        ((total_links++))

        # 解析相对路径
        local target_file="$file_dir/$link"

        # 处理带 #anchor 的链接
        local anchor=""
        if [[ $link == *"#"* ]]; then
            target_file=$(echo "$target_file" | cut -d'#' -f1)
            anchor=$(echo "$link" | cut -d'#' -f2)
        fi

        # 检查目标文件是否存在
        if [ ! -f "$target_file" ]; then
            print_error "$file: 无效链接 $link"
            ((invalid_links++))
        fi
    done
}

# 检查所有 Markdown 文档
print_header "检查文档链接"

# 检查主要文档目录
for file in $(find docs .claude .kiro -name "*.md" -type f 2>/dev/null); do
    check_links_in_file "$file"
done

# 检查插件 README
for file in $(find lib/plugins -name "README.md" -type f 2>/dev/null); do
    check_links_in_file "$file"
done

# 输出结果
print_header "检查结果"

echo "总链接数: $total_links"
echo "无效链接: $invalid_links"

if [ $invalid_links -eq 0 ]; then
    print_success "所有链接都有效！"
    exit 0
else
    print_error "发现 $invalid_links 个无效链接"
    echo ""
    print_info "请修复上述无效链接后重新检查"
    exit 1
fi
