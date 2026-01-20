#!/bin/bash
# 重构完整性检查脚本
# 用法: .claude/scripts/check_refactoring.sh <搜索模式> [描述]

set -e

SEARCH_PATTERN=$1
DESCRIPTION=${2:-"重构检查"}

echo "🔍 开始: $DESCRIPTION"
echo "🎯 搜索模式: $SEARCH_PATTERN"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 搜索 Dart 文件
echo "📂 搜索 Dart 文件..."
DART_RESULTS=$(grep -rn "$SEARCH_PATTERN" --include="*.dart" lib/ 2>/dev/null || true)
DART_COUNT=$(echo "$DART_RESULTS" | grep -v "^$" | wc -l)

if [ $DART_COUNT -gt 0 ]; then
    echo -e "${RED}❌ 发现 $DART_COUNT 处引用在 Dart 文件中:${NC}"
    echo "$DART_RESULTS"
    echo ""
else
    echo -e "${GREEN}✅ Dart 文件中未发现引用${NC}"
fi

# 搜索 ARB 文件
echo "📂 搜索国际化文件..."
ARGB_RESULTS=$(grep -rn "$SEARCH_PATTERN" --include="*.arb" lib/l10n/ 2>/dev/null || true)
ARGB_COUNT=$(echo "$ARGB_RESULTS" | grep -v "^$" | wc -l)

if [ $ARGB_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠️  发现 $ARGB_COUNT 处引用在 ARB 文件中:${NC}"
    echo "$ARGB_RESULTS"
    echo ""
else
    echo -e "${GREEN}✅ ARB 文件中未发现引用${NC}"
fi

# 搜索生成的国际化文件
echo "📂 搜索生成的国际化文件..."
GEN_RESULTS=$(grep -rn "$SEARCH_PATTERN" --include="*.dart" lib/l10n/generated/ 2>/dev/null || true)
GEN_COUNT=$(echo "$GEN_RESULTS" | grep -v "^$" | wc -l)

if [ $GEN_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠️  发现 $GEN_COUNT 处引用在生成的文件中（需要重新生成）:${NC}"
    echo "$GEN_RESULTS"
    echo ""
else
    echo -e "${GREEN}✅ 生成的文件中未发现引用${NC}"
fi

# 总结
TOTAL_COUNT=$((DART_COUNT + ARGB_COUNT + GEN_COUNT))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $TOTAL_COUNT -gt 0 ]; then
    echo -e "${RED}❌ 检查失败：共发现 $TOTAL_COUNT 处引用${NC}"
    echo ""
    echo "建议操作："
    echo "1. 检查上述文件"
    echo "2. 移除或更新相关引用"
    echo "3. 如果是 ARB 文件，运行: flutter gen-l10n"
    echo "4. 重新运行此脚本"
    exit 1
else
    echo -e "${GREEN}🎉 检查通过：未发现遗留引用${NC}"
    exit 0
fi
