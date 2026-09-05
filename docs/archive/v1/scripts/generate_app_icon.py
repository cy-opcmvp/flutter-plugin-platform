"""
应用图标生成脚本

生成一个3:4比例的长方形蓝色图标，中间有一个白色大写字母P。
支持生成多种尺寸的PNG和ICO文件。
"""

from PIL import Image, ImageDraw, ImageFont
import os

# 图标配置
ICON_RATIO = 3 / 4  # 宽高比 3:4
BG_COLOR = (41, 98, 255)  # 蓝色背景 (#2962FF)
TEXT_COLOR = (255, 255, 255)  # 白色文字
TEXT = "P"  # 大写字母P

# 需要生成的尺寸（用于不同平台）
SIZES = {
    # Windows sizes
    'ico': [16, 32, 48, 64, 128, 256],
    # macOS sizes
    'mac': [16, 32, 64, 128, 256, 512, 1024],
    # General sizes
    'png': [48, 64, 128, 256, 512, 1024],
}


def create_icon(size):
    """
    创建指定尺寸的图标

    Args:
        size: 图标尺寸（正方形边长）

    Returns:
        PIL.Image对象
    """
    # 创建正方形画布
    img = Image.new('RGB', (size, size), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # 计算长方形框的尺寸（3:4比例）
    # 在正方形画布上居中
    rect_width = int(size * 0.7)  # 宽度占70%
    rect_height = int(rect_width / ICON_RATIO)  # 高度按3:4比例

    # 确保不超出画布
    if rect_height > size:
        rect_height = int(size * 0.9)
        rect_width = int(rect_height * ICON_RATIO)

    # 计算居中位置
    x1 = (size - rect_width) // 2
    y1 = (size - rect_height) // 2
    x2 = x1 + rect_width
    y2 = y1 + rect_height

    # 绘制蓝色长方形框（带边框）
    border_width = max(2, size // 32)  # 边框宽度根据尺寸调整
    draw.rectangle([x1, y1, x2, y2],
                   fill=BG_COLOR,
                   outline=(255, 255, 255),
                   width=border_width)

    # 绘制大写字母P
    try:
        # 尝试使用系统字体
        font_size = int(rect_height * 0.6)
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        # 如果找不到字体，使用默认字体
        font = ImageFont.load_default()

    # 获取文字边界框以居中
    bbox = draw.textbbox((0, 0), TEXT, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # 计算文字居中位置
    text_x = x1 + (rect_width - text_width) // 2
    text_y = y1 + (rect_height - text_height) // 2

    # 绘制文字（带阴影效果）
    shadow_offset = max(1, size // 128)
    draw.text((text_x + shadow_offset, text_y + shadow_offset),
              TEXT, fill=(0, 0, 0, 128), font=font)
    draw.text((text_x, text_y), TEXT, fill=TEXT_COLOR, font=font)

    return img


def save_icon(img, path, size):
    """保存图标到指定路径"""
    img.save(path)
    print(f"✓ 生成 {size}x{size}: {path}")


def generate_ico():
    """生成Windows ICO文件"""
    print("\n生成 Windows ICO 文件...")

    # 创建所有需要的尺寸
    images = []
    for size in SIZES['ico']:
        img = create_icon(size)
        images.append(img)

    # 保存ICO文件
    ico_path = os.path.join('windows', 'runner', 'resources', 'app_icon.ico')
    os.makedirs(os.path.dirname(ico_path), exist_ok=True)

    # 保存为ICO格式
    images[0].save(ico_path,
                   format='ICO',
                   sizes=[(size, size) for size in SIZES['ico']])
    print(f"✓ 生成 ICO: {ico_path}")


def generate_mac_icons():
    """生成macOS图标文件"""
    print("\n生成 macOS 图标文件...")

    base_path = os.path.join('macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(base_path, exist_ok=True)

    for size in SIZES['mac']:
        img = create_icon(size)
        filename = f'app_icon_{size}.png'
        path = os.path.join(base_path, filename)
        save_icon(img, path, size)


def generate_png_icons():
    """生成通用PNG图标"""
    print("\n生成 PNG 图标文件...")

    output_dir = os.path.join('assets', 'icons')
    os.makedirs(output_dir, exist_ok=True)

    for size in SIZES['png']:
        img = create_icon(size)
        filename = f'app_icon_{size}x{size}.png'
        path = os.path.join(output_dir, filename)
        save_icon(img, path, size)


def generate_preview():
    """生成预览图"""
    print("\n生成预览图...")

    # 创建一个包含所有尺寸的预览图
    preview_size = 1200
    preview = Image.new('RGB', (preview_size, preview_size), (240, 240, 240))
    draw = ImageDraw.Draw(preview)

    # 标题
    try:
        title_font = ImageFont.truetype("arial.ttf", 40)
    except:
        title_font = ImageFont.load_default()

    title = "App Icon Preview - Multi-Function Plugin Platform"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = bbox[2] - bbox[0]
    draw.text(((preview_size - title_width) // 2, 30), title, fill=(0, 0, 0), font=title_font)

    # 绘制不同尺寸的图标
    sizes_to_show = [64, 128, 256]
    y_offset = 100

    for size in sizes_to_show:
        img = create_icon(size)
        x = (preview_size - size) // 2
        preview.paste(img, (x, y_offset))

        # 添加尺寸标签
        label = f"{size}x{size}"
        bbox = draw.textbbox((0, 0), label, font=title_font)
        label_width = bbox[2] - bbox[0]
        draw.text(((preview_size - label_width) // 2, y_offset + size + 10),
                 label, fill=(80, 80, 80), font=title_font)

        y_offset += size + 60

    preview_path = 'assets/icon_preview.png'
    os.makedirs(os.path.dirname(preview_path), exist_ok=True)
    preview.save(preview_path)
    print(f"✓ 生成预览图: {preview_path}")


def main():
    """主函数"""
    print("=" * 60)
    print("多功能插件平台 - 图标生成器")
    print("=" * 60)
    print(f"图标设计: 3:4比例的蓝色长方形框，中间有白色大写P")
    print(f"背景色: RGB{BG_COLOR}")
    print(f"文字色: RGB{TEXT_COLOR}")
    print("=" * 60)

    # 生成所有图标
    generate_ico()
    generate_mac_icons()
    generate_png_icons()
    generate_preview()

    print("\n" + "=" * 60)
    print("✓ 所有图标生成完成！")
    print("=" * 60)
    print("\n使用说明:")
    print("1. Windows: 图标已保存到 windows/runner/resources/app_icon.ico")
    print("2. macOS: 图标已保存到 macos/Runner/Assets.xcassets/AppIcon.appiconset/")
    print("3. 通用PNG: 图标已保存到 assets/icons/")
    print("4. 预览图: 已保存到 assets/icon_preview.png")
    print("\n请重新编译项目以应用新图标。")


if __name__ == '__main__':
    main()
