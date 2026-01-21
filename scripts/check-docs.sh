#!/bin/bash

##############################################################################
# 文档变更检查脚本
#
# 用途：在 git commit 前检查代码变更是否伴随相应的文档更新
# 使用：在 git hooks 中调用，或手动运行 ./scripts/check-docs.sh
#
# 作者：Claude Code
# 版本：v1.0.0
# 更新：2026-01-21
##############################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# 检查是否在 git 仓库中
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "当前目录不是 git 仓库"
        exit 1
    fi
}

# 获取变更的文件
get_changed_files() {
    local diff_target=${1:-"HEAD"}

    # 获取相对于项目根目录的变更文件
    git diff --name-only --diff-filter=d "$diff_target" | grep -v "^build/" | grep -v "^\.dart_tool/"
}

# 获取暂存区的变更文件
get_staged_files() {
    git diff --cached --name-only --diff-filter=d | grep -v "^build/" | grep -v "^\.dart_tool/"
}

# 检查插件代码变更
check_plugin_changes() {
    local changed_files=$1
    local plugin_docs_updated=false
    local plugin_code_changed=false
    local plugin_names=()

    print_header "检查插件代码与文档同步"

    # 检查是否有插件代码变更
    for file in $changed_files; do
        if [[ $file == lib/plugins/* ]] && [[ $file != *.md ]]; then
            plugin_code_changed=true
            # 提取插件名称
            local plugin_name=$(echo "$file" | cut -d/ -f3)
            if [[ ! " ${plugin_names[@]} " =~ " ${plugin_name} " ]]; then
                plugin_names+=("$plugin_name")
            fi
        fi
    done

    # 检查是否有插件文档变更
    for file in $changed_files; do
        if [[ $file == docs/plugins/* ]] || [[ $file == lib/plugins/*/config/*_config_docs.md ]]; then
            plugin_docs_updated=true
            break
        fi
    done

    if $plugin_code_changed && ! $plugin_docs_updated; then
        print_warning "检测到插件代码变更，但未更新相关文档"
        echo ""
        echo "涉及的插件："
        for plugin in "${plugin_names[@]}"; do
            echo "  - $plugin"
            echo "    可能需要更新的文档："
            echo "      • docs/plugins/$plugin/README.md"
            if [ -f "lib/plugins/$plugin/config/${plugin}_config_docs.md" ]; then
                echo "      • lib/plugins/$plugin/config/${plugin}_config_docs.md"
            fi
        done
        echo ""
        print_info "如果这是不需要更新文档的变更（如 bug 修复），请忽略此警告"
        return 1
    else
        print_success "插件代码与文档同步检查通过"
        return 0
    fi
}

# 检查配置文件变更
check_config_changes() {
    local changed_files=$1

    print_header "检查配置文件与文档同步"

    local config_changed=false
    local config_doc_changed=false

    for file in $changed_files; do
        # 检查是否修改了配置默认值
        if [[ $file == lib/plugins/*/config/*_config_defaults.dart ]]; then
            config_changed=true
            local plugin_name=$(echo "$file" | cut -d/ -f3)
            print_info "插件 $plugin_name 的配置默认值已变更"
        fi

        # 检查是否更新了配置文档
        if [[ $file == lib/plugins/*/config/*_config_docs.md ]]; then
            config_doc_changed=true
        fi
    done

    if $config_changed && ! $config_doc_changed; then
        print_warning "配置文件已变更，但配置文档未更新"
        print_info "请检查是否需要更新相应的 *_config_docs.md 文件"
        return 1
    else
        print_success "配置文件与文档同步检查通过"
        return 0
    fi
}

# 检查平台服务变更
check_platform_service_changes() {
    local changed_files=$1

    print_header "检查平台服务文档同步"

    local service_changed=false
    local service_doc_changed=false

    for file in $changed_files; do
        # 检查是否修改了平台服务代码
        if [[ $file == lib/core/services/* ]] && [[ $file != *.md ]]; then
            service_changed=true
            print_info "检测到平台服务代码变更: $file"
        fi

        # 检查是否更新了服务文档
        if [[ $file == docs/platform-services/* ]] || [[ $file == docs/guides/platform-services-user-guide.md ]]; then
            service_doc_changed=true
        fi
    done

    if $service_changed && ! $service_doc_changed; then
        print_warning "平台服务代码已变更，但相关文档未更新"
        print_info "可能需要更新的文档："
        echo "  • docs/platform-services/README.md"
        echo "  • docs/guides/platform-services-user-guide.md"
        return 1
    else
        print_success "平台服务与文档同步检查通过"
        return 0
    fi
}

# 检查国际化变更
check_i18n_changes() {
    local changed_files=$1

    print_header "检查国际化文件同步"

    local arbs_changed=false
    local both_arbs_changed=false

    local zh_changed=false
    local en_changed=false

    for file in $changed_files; do
        if [[ $file == lib/l10n/app_zh.arb ]]; then
            zh_changed=true
            arbs_changed=true
        fi
        if [[ $file == lib/l10n/app_en.arb ]]; then
            en_changed=true
            arbs_changed=true
        fi
    done

    if $arbs_changed; then
        if $zh_changed && ! $en_changed; then
            print_warning "app_zh.arb 已变更，但 app_en.arb 未同步"
            return 1
        elif $en_changed && ! $zh_changed; then
            print_warning "app_en.arb 已变更，但 app_zh.arb 未同步"
            return 1
        fi
    fi

    print_success "国际化文件同步检查通过"
    return 0
}

# 检查文档链接有效性
check_doc_links() {
    local changed_files=$1

    print_header "检查文档中的链接"

    local has_invalid_links=false

    for file in $changed_files; do
        if [[ $file == *.md ]]; then
            # 提取文档中的相对链接
            local links=$(grep -oE '\[.*\]\(([^)]+)\)' "$file" | grep -oE '\(([^)]+)\)' | tr -d '()' | grep -E '^\.\./|^\./')

            for link in $links; do
                # 解析相对路径
                local target_file=$(dirname "$file")/$link
                if [ ! -f "$target_file" ]; then
                    print_warning "文档 $file 中存在无效链接: $link"
                    has_invalid_links=true
                fi
            done
        fi
    done

    if ! $has_invalid_links; then
        print_success "文档链接检查通过"
    fi

    return 0
}

# 检查 CHANGELOG
check_changelog() {
    local changed_files=$1

    print_header "检查 CHANGELOG.md"

    # 检查是否有需要记录到 CHANGELOG 的变更
    local has_significant_changes=false

    for file in $changed_files; do
        # 新增插件
        if [[ $file == lib/plugins/* ]] && [[ $file == */*_plugin.dart ]]; then
            has_significant_changes=true
            print_info "检测到新插件: $file"
        fi

        # 新增服务
        if [[ $file == lib/core/services/*/*_service.dart ]]; then
            has_significant_changes=true
            print_info "检测到新服务: $file"
        fi
    done

    if $has_significant_changes; then
        if [[ ! " ${changed_files[*]} " =~ " CHANGELOG.md " ]]; then
            print_warning "检测到重要功能变更，但 CHANGELOG.md 未更新"
            print_info "如果这是不应记录到 CHANGELOG 的变更（如重构），请忽略"
            return 1
        fi
    fi

    print_success "CHANGELOG.md 检查通过"
    return 0
}

# 主函数
main() {
    print_header "📚 文档变更检查工具"

    # 检查参数
    local check_mode=${1:-"staged"}
    local files_to_check=()

    if [ "$check_mode" = "staged" ]; then
        print_info "检查暂存区的文件变更..."
        files_to_check=($(get_staged_files))
    elif [ "$check_mode" = "committed" ]; then
        print_info "检查最近一次提交的变更..."
        files_to_check=($(get_changed_files "HEAD~1"))
    else
        print_error "无效的检查模式: $check_mode"
        echo "使用方式: $0 [staged|committed]"
        exit 1
    fi

    if [ ${#files_to_check[@]} -eq 0 ]; then
        print_info "没有检测到文件变更"
        exit 0
    fi

    echo "检测到 ${#files_to_check[@]} 个文件变更"
    echo ""

    # 执行各项检查
    local total_checks=0
    local failed_checks=0

    check_plugin_changes "${files_to_check[*]}" || ((failed_checks++))
    ((total_checks++))

    check_config_changes "${files_to_check[*]}" || ((failed_checks++))
    ((total_checks++))

    check_platform_service_changes "${files_to_check[*]}" || ((failed_checks++))
    ((total_checks++))

    check_i18n_changes "${files_to_check[*]}" || ((failed_checks++))
    ((total_checks++))

    check_doc_links "${files_to_check[*]}" || ((failed_checks++))
    ((total_checks++))

    check_changelog "${files_to_check[*]}" || ((failed_checks++))
    ((total_checks++))

    # 输出总结
    print_header "检查总结"
    echo "总检查数: $total_checks"
    echo "失败数: $failed_checks"

    if [ $failed_checks -gt 0 ]; then
        echo ""
        print_warning "部分检查未通过"
        print_info "如果确认这些警告可以忽略，可以使用 git commit --no-verify 跳过检查"
        exit 1
    else
        echo ""
        print_success "所有检查通过！"
        exit 0
    fi
}

# 运行主函数
main "$@"
