#!/bin/bash

##############################################################################
# 文档覆盖率检查脚本
#
# 用途：检查文档覆盖率，确保代码和功能都有对应文档
# 使用：./scripts/check-doc-coverage.sh
#
# 作者：Claude Code
# 版本：v1.0.0
# 更新：2026-01-21
##############################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "📊 文档覆盖率检查"
echo ""

# 总体统计
total_checks=0
passed_checks=0

# 检查插件文档覆盖率
print_header "1. 插件文档覆盖率"

plugin_count=$(find lib/plugins -maxdepth 1 -type d ! -name plugins | wc -l)
doc_count=$(find docs/plugins -maxdepth 1 -type d ! -name plugins | wc -l)
plugin_readme_count=$(find docs/plugins -name "README.md" | wc -l)

print_info "插件数量: $plugin_count"
print_info "插件文档目录: $doc_count"
print_info "插件 README: $plugin_readme_count"

if [ $plugin_readme_count -lt $plugin_count ]; then
    print_warning "部分插件缺少 README 文档"
    print_info "插件覆盖率: $(echo "scale=1; $plugin_readme_count * 100 / $plugin_count" | bc)%"

    # 找出缺少文档的插件
    echo ""
    print_info "缺少文档的插件："
    for plugin_dir in lib/plugins/*/; do
        plugin_name=$(basename "$plugin_dir")
        if [ ! -f "docs/plugins/$plugin_name/README.md" ]; then
            echo "  - $plugin_name"
        fi
    done
    ((total_checks++))
else
    print_success "所有插件都有 README 文档"
    ((total_checks++))
    ((passed_checks++))
fi

# 检查配置文档覆盖率
print_header "2. 配置文档覆盖率"

config_count=$(find lib/plugins/*/config -name "*_settings.dart" 2>/dev/null | wc -l)
config_doc_count=$(find lib/plugins/*/config -name "*_config_docs.md" 2>/dev/null | wc -l)

print_info "配置模型数量: $config_count"
print_info "配置文档数量: $config_doc_count"

if [ $config_count -gt 0 ]; then
    if [ $config_doc_count -lt $config_count ]; then
        print_warning "部分配置缺少文档"
        print_info "配置文档覆盖率: $(echo "scale=1; $config_doc_count * 100 / $config_count" | bc)%"

        # 找出缺少文档的配置
        echo ""
        print_info "缺少文档的配置："
        for config_file in lib/plugins/*/config/*_settings.dart; do
            if [ -f "$config_file" ]; then
                plugin_name=$(echo "$config_file" | cut -d/ -f3)
                config_name=$(basename "$config_file" _settings.dart)
                config_doc="lib/plugins/$plugin_name/config/${config_name}_config_docs.md"
                if [ ! -f "$config_doc" ]; then
                    echo "  - $plugin_name/$config_name"
                fi
            fi
        done
        ((total_checks++))
    else
        print_success "所有配置都有文档"
        ((total_checks++))
        ((passed_checks++))
    fi
else
    print_info "没有找到配置文件"
fi

# 检查规范文档完整性
print_header "3. 规范文档完整性"

required_rules=(
    "CODE_STYLE_RULES.md"
    "TESTING_RULES.md"
    "GIT_COMMIT_RULES.md"
    "ERROR_HANDLING_RULES.md"
    "VERSION_CONTROL_RULES.md"
    "PLUGIN_CONFIG_SPEC.md"
    "JSON_CONFIG_RULES.md"
    "DOCUMENTATION_NAMING_RULES.md"
    "FILE_ORGANIZATION_RULES.md"
)

missing_rules=0
for rule in "${required_rules[@]}"; do
    if [ ! -f ".claude/rules/$rule" ]; then
        print_error "缺少规范: $rule"
        ((missing_rules++))
    fi
done

if [ $missing_rules -eq 0 ]; then
    print_success "所有必需的规范文档都存在"
    ((total_checks++))
    ((passed_checks++))
else
    print_warning "缺少 $missing_rules 个规范文档"
    ((total_checks++))
fi

# 检查技术规范文档
print_header "4. 技术规范文档"

spec_dirs=(
    ".kiro/specs/platform-services"
    ".kiro/specs/plugin-platform"
    ".kiro/specs/external-plugin-system"
    ".kiro/specs/internationalization"
    ".kiro/specs/web-platform-compatibility"
)

for spec_dir in "${spec_dirs[@]}"; do
    spec_name=$(basename "$spec_dir")
    if [ -d "$spec_dir" ]; then
        has_requirements=false
        has_design=false
        has_tasks=false

        [ -f "$spec_dir/requirements.md" ] && has_requirements=true
        [ -f "$spec_dir/design.md" ] && has_design=true
        [ -f "$spec_dir/tasks.md" ] && has_tasks=true

        if $has_requirements && $has_design && $has_tasks; then
            print_success "$spec_name: 规范完整（requirements, design, tasks）"
        else
            print_warning "$spec_name: 规范不完整"
            $has_requirements || echo "  - 缺少 requirements.md"
            $has_design || echo "  - 缺少 design.md"
            $has_tasks || echo "  - 缺少 tasks.md"
        fi
        ((total_checks++))
        [ "$has_requirements" = true ] && [ "$has_design" = true ] && [ "$has_tasks" = true ] && ((passed_checks++))
    fi
done

# 检查平台服务文档
print_header "5. 平台服务文档"

platform_service_docs=(
    "docs/platform-services/README.md"
    "docs/platform-services/quick-start.md"
    "docs/platform-services/structure.md"
    "docs/guides/platform-services-user-guide.md"
)

for doc in "${platform_service_docs[@]}"; do
    if [ -f "$doc" ]; then
        print_success "存在: $(basename $doc)"
        ((total_checks++))
        ((passed_checks++))
    else
        print_warning "缺失: $doc"
        ((total_checks++))
    fi
done

# 检查用户指南
print_header "6. 用户指南文档"

user_guides=(
    "docs/guides/getting-started.md"
    "docs/guides/internal-plugin-development.md"
    "docs/guides/external-plugin-development.md"
)

for guide in "${user_guides[@]}"; do
    if [ -f "$guide" ]; then
        print_success "存在: $(basename $guide)"
        ((total_checks++))
        ((passed_checks++))
    else
        print_warning "缺失: $guide"
        ((total_checks++))
    fi
done

# 输出总结
print_header "检查总结"

echo "总检查项: $total_checks"
echo "通过数量: $passed_checks"
echo "失败数量: $((total_checks - passed_checks))"

if [ $passed_checks -eq $total_checks ]; then
    coverage="100%"
    print_success "文档覆盖率: $coverage"
    echo ""
    print_success "所有检查通过！"
    exit 0
else
    coverage=$(echo "scale=1; $passed_checks * 100 / $total_checks" | bc)
    print_warning "文档覆盖率: $coverage%"
    echo ""
    print_info "请根据上述提示补充缺失的文档"
    exit 1
fi
