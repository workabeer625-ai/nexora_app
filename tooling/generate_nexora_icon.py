from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
ASSETS_DIR = ROOT / "assets" / "branding"
IMAGES_DIR = ROOT / "assets" / "images"
MASTER_PNG_PATH = ASSETS_DIR / "nexora_app_icon.png"
ROUNDED_PREVIEW_PNG_PATH = ASSETS_DIR / "nexora_app_icon_rounded.png"
MASTER_SVG_PATH = ASSETS_DIR / "nexora_app_icon.svg"
TRANSPARENT_MARK_PNG_PATH = IMAGES_DIR / "nexora_brand_mark.png"
COMPACT_MARK_PNG_PATH = IMAGES_DIR / "nexora_brand_mark_compact.png"

IOS_ICONSET_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
IOS_CONTENTS_PATH = IOS_ICONSET_DIR / "Contents.json"

ANDROID_MIPMAPS = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

WEB_ICONS = {
    ROOT / "web" / "favicon.png": 64,
    ROOT / "web" / "icons" / "Icon-192.png": 192,
    ROOT / "web" / "icons" / "Icon-512.png": 512,
    ROOT / "web" / "icons" / "Icon-maskable-192.png": 192,
    ROOT / "web" / "icons" / "Icon-maskable-512.png": 512,
}

SIZE = 1024
BG_BASE = "#0B1120"
BG_TOP = "#121C34"
BG_BOTTOM = "#060B16"
N_BLUE = "#38BDF8"
N_INDIGO = "#4F46E5"
N_PURPLE = "#8B5CF6"


def hex_to_rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    return (
        int(value[0:2], 16),
        int(value[2:4], 16),
        int(value[4:6], 16),
        alpha,
    )


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def interpolate_color(
    start: tuple[int, int, int, int],
    end: tuple[int, int, int, int],
    t: float,
) -> tuple[int, int, int, int]:
    return tuple(round(lerp(sa, ea, t)) for sa, ea in zip(start, end))


def make_horizontal_gradient(
    width: int,
    height: int,
    stops: list[tuple[float, tuple[int, int, int, int]]],
) -> Image.Image:
    strip = Image.new("RGBA", (width, 1))
    pixels = strip.load()
    stop_index = 0

    for x in range(width):
        pos = x / (width - 1)
        while stop_index + 1 < len(stops) and pos > stops[stop_index + 1][0]:
            stop_index += 1
        left_stop = stops[stop_index]
        right_stop = stops[min(stop_index + 1, len(stops) - 1)]
        if right_stop[0] == left_stop[0]:
            color = left_stop[1]
        else:
            local_t = (pos - left_stop[0]) / (right_stop[0] - left_stop[0])
            color = interpolate_color(left_stop[1], right_stop[1], local_t)
        pixels[x, 0] = color

    return strip.resize((width, height), resample=Image.Resampling.BICUBIC)


def apply_mask(image: Image.Image, mask: Image.Image) -> Image.Image:
    masked = image.copy()
    alpha = masked.getchannel("A")
    masked.putalpha(ImageChops.multiply(alpha, mask))
    return masked


def add_soft_glow(
    canvas: Image.Image,
    bbox: tuple[int, int, int, int],
    color: tuple[int, int, int, int],
    blur: int,
) -> None:
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    draw.ellipse(bbox, fill=color)
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(blur)))


def draw_rounded_segment(
    draw: ImageDraw.ImageDraw,
    start: tuple[float, float],
    end: tuple[float, float],
    width: float,
    fill,
) -> None:
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    length = math.hypot(dx, dy)
    nx = -dy / length
    ny = dx / length
    half_width = width / 2

    polygon = [
        (start[0] + nx * half_width, start[1] + ny * half_width),
        (start[0] - nx * half_width, start[1] - ny * half_width),
        (end[0] - nx * half_width, end[1] - ny * half_width),
        (end[0] + nx * half_width, end[1] + ny * half_width),
    ]
    draw.polygon(polygon, fill=fill)
    draw.ellipse(
        (
            start[0] - half_width,
            start[1] - half_width,
            start[0] + half_width,
            start[1] + half_width,
        ),
        fill=fill,
    )
    draw.ellipse(
        (
            end[0] - half_width,
            end[1] - half_width,
            end[0] + half_width,
            end[1] + half_width,
        ),
        fill=fill,
    )


def create_symbol_mask(size: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)

    left = (248, 224, 388, 800)
    right = (636, 224, 776, 800)
    draw.rounded_rectangle(left, radius=70, fill=255)
    draw.rounded_rectangle(right, radius=70, fill=255)
    draw_rounded_segment(draw, (400, 348), (624, 680), 150, 255)

    # Slight inset softens junctions for clearer small-size rendering.
    return mask.filter(ImageFilter.GaussianBlur(1))


def create_background(size: int) -> Image.Image:
    horizontal = make_horizontal_gradient(
        size,
        size,
        [
            (0.0, hex_to_rgba(BG_TOP, 255)),
            (0.55, hex_to_rgba("#0C1426", 255)),
            (1.0, hex_to_rgba("#07101E", 255)),
        ],
    )
    vertical = make_horizontal_gradient(
        size,
        size,
        [
            (0.0, hex_to_rgba("#111A30", 255)),
            (1.0, hex_to_rgba(BG_BOTTOM, 255)),
        ],
    ).rotate(90, resample=Image.Resampling.BICUBIC, expand=False)
    background = Image.blend(horizontal, vertical, 0.4)

    add_soft_glow(background, (70, 40, 520, 420), hex_to_rgba(N_BLUE, 42), 120)
    add_soft_glow(background, (530, 420, 980, 980), hex_to_rgba(N_PURPLE, 34), 150)
    add_soft_glow(background, (320, 260, 900, 860), hex_to_rgba("#111827", 28), 180)

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(highlight)
    draw.ellipse((140, -120, 940, 440), fill=(255, 255, 255, 22))
    background.alpha_composite(highlight.filter(ImageFilter.GaussianBlur(90)))

    vignette = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(vignette)
    draw.ellipse((-120, -120, size + 120, size + 120), fill=(0, 0, 0, 0))
    draw.rectangle((0, 0, size, size), fill=(2, 6, 14, 52))
    vignette = vignette.filter(ImageFilter.GaussianBlur(100))
    background.alpha_composite(vignette)
    return background


def create_symbol_layer(size: int, mask: Image.Image) -> Image.Image:
    gradient = make_horizontal_gradient(
        size,
        size,
        [
            (0.0, hex_to_rgba(N_BLUE)),
            (0.55, hex_to_rgba(N_INDIGO)),
            (1.0, hex_to_rgba(N_PURPLE)),
        ],
    )

    glow_mask = mask.filter(ImageFilter.GaussianBlur(58)).point(lambda value: min(255, int(value * 0.28)))
    glow = gradient.copy()
    glow.putalpha(glow_mask)

    symbol = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    symbol.alpha_composite(glow)

    base_symbol = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    base_symbol.paste(gradient, mask=mask)
    symbol.alpha_composite(base_symbol)

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(highlight)
    draw.ellipse((120, 90, 660, 630), fill=(255, 255, 255, 96))
    draw.ellipse((210, 120, 740, 560), fill=(255, 255, 255, 54))
    highlight = apply_mask(highlight.filter(ImageFilter.GaussianBlur(82)), mask)
    symbol.alpha_composite(highlight)

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.ellipse((380, 360, 930, 970), fill=(4, 8, 18, 120))
    shadow = apply_mask(shadow.filter(ImageFilter.GaussianBlur(110)), mask)
    symbol.alpha_composite(shadow)

    edge_mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(edge_mask)
    draw_rounded_segment(draw, (388, 332), (612, 662), 58, 255)
    edge_mask = ImageChops.multiply(mask, edge_mask.filter(ImageFilter.GaussianBlur(20)))
    edge_sheen = Image.new("RGBA", (size, size), (255, 255, 255, 38))
    edge_sheen.putalpha(edge_mask.point(lambda value: min(255, int(value * 0.28))))
    symbol.alpha_composite(edge_sheen)

    return symbol


def render_master_icon(size: int = SIZE) -> Image.Image:
    background = create_background(size)
    mask = create_symbol_mask(size)
    symbol = create_symbol_layer(size, mask)
    background.alpha_composite(symbol)
    return background


def render_transparent_mark(size: int = SIZE) -> Image.Image:
    mask = create_symbol_mask(size)
    symbol = create_symbol_layer(size, mask)

    alpha_bounds = symbol.getchannel("A").getbbox()
    if alpha_bounds is None:
        return symbol

    left, top, right, bottom = alpha_bounds
    width = right - left
    height = bottom - top
    padding = int(max(width, height) * 0.08)
    cropped = symbol.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(size, right + padding),
            min(size, bottom + padding),
        )
    )

    target = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fit = ImageOps.contain(cropped, (size, size), Image.Resampling.LANCZOS)
    offset = ((size - fit.width) // 2, (size - fit.height) // 2)
    target.alpha_composite(fit, offset)
    return target


def render_compact_mark(size: int = SIZE) -> Image.Image:
    mask = create_symbol_mask(size)
    gradient = make_horizontal_gradient(
        size,
        size,
        [
            (0.0, hex_to_rgba(N_BLUE)),
            (0.55, hex_to_rgba(N_INDIGO)),
            (1.0, hex_to_rgba(N_PURPLE)),
        ],
    )

    symbol = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    base_symbol = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    base_symbol.paste(gradient, mask=mask)
    symbol.alpha_composite(base_symbol)

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(highlight)
    draw.ellipse((180, 140, 640, 620), fill=(255, 255, 255, 84))
    draw.ellipse((260, 180, 720, 560), fill=(255, 255, 255, 36))
    highlight = apply_mask(highlight.filter(ImageFilter.GaussianBlur(58)), mask)
    symbol.alpha_composite(highlight)

    edge_mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(edge_mask)
    draw_rounded_segment(draw, (388, 332), (612, 662), 42, 255)
    edge_mask = ImageChops.multiply(mask, edge_mask.filter(ImageFilter.GaussianBlur(12)))
    edge_sheen = Image.new("RGBA", (size, size), (255, 255, 255, 26))
    edge_sheen.putalpha(edge_mask.point(lambda value: min(255, int(value * 0.34))))
    symbol.alpha_composite(edge_sheen)

    alpha_bounds = symbol.getchannel("A").getbbox()
    if alpha_bounds is None:
        return symbol

    left, top, right, bottom = alpha_bounds
    width = right - left
    height = bottom - top
    padding = int(max(width, height) * 0.03)
    cropped = symbol.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(size, right + padding),
            min(size, bottom + padding),
        )
    )

    target = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fit = ImageOps.contain(cropped, (size, size), Image.Resampling.LANCZOS)
    offset = ((size - fit.width) // 2, (size - fit.height) // 2)
    target.alpha_composite(fit, offset)
    return target


def save_png(path: Path, image: Image.Image, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    output = image.resize((size, size), resample=Image.Resampling.LANCZOS)
    if "A" in output.getbands():
        output.save(path)
    else:
        output.convert("RGB").save(path)


def save_rounded_preview(path: Path, image: Image.Image, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    preview = image.resize((size, size), resample=Image.Resampling.LANCZOS)
    rounded_mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(rounded_mask)
    draw.rounded_rectangle((46, 46, size - 46, size - 46), radius=220, fill=255)
    preview.putalpha(rounded_mask)
    preview.save(path)


def save_ios_icons(master: Image.Image) -> None:
    contents = json.loads(IOS_CONTENTS_PATH.read_text(encoding="utf-8"))
    for item in contents["images"]:
        filename = item.get("filename")
        if not filename:
            continue
        points = float(item["size"].split("x")[0])
        scale = int(item["scale"].rstrip("x"))
        pixel_size = round(points * scale)
        save_png(IOS_ICONSET_DIR / filename, master, pixel_size)


def save_android_icons(master: Image.Image) -> None:
    for density, pixel_size in ANDROID_MIPMAPS.items():
        path = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}" / "ic_launcher.png"
        save_png(path, master, pixel_size)


def save_web_icons(master: Image.Image) -> None:
    for path, pixel_size in WEB_ICONS.items():
        save_png(path, master, pixel_size)


def write_master_svg(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    svg = f"""<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <clipPath id="tile">
      <rect x="46" y="46" width="932" height="932" rx="220" />
    </clipPath>
    <linearGradient id="bg" x1="142" y1="112" x2="884" y2="910" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="{BG_TOP}" />
      <stop offset="0.55" stop-color="#0C1426" />
      <stop offset="1" stop-color="{BG_BOTTOM}" />
    </linearGradient>
    <linearGradient id="n" x1="248" y1="512" x2="776" y2="512" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="{N_BLUE}" />
      <stop offset="0.55" stop-color="{N_INDIGO}" />
      <stop offset="1" stop-color="{N_PURPLE}" />
    </linearGradient>
    <radialGradient id="glowBlue" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(286 216) rotate(32) scale(296 252)">
      <stop stop-color="{N_BLUE}" stop-opacity="0.24" />
      <stop offset="1" stop-color="{N_BLUE}" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="glowPurple" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(762 748) rotate(20) scale(344 312)">
      <stop stop-color="{N_PURPLE}" stop-opacity="0.2" />
      <stop offset="1" stop-color="{N_PURPLE}" stop-opacity="0" />
    </radialGradient>
    <filter id="blurLarge" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="54" />
    </filter>
    <filter id="blurSoft" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="28" />
    </filter>
  </defs>
  <g clip-path="url(#tile)">
    <rect width="1024" height="1024" fill="{BG_BASE}" />
    <rect width="1024" height="1024" fill="url(#bg)" />
    <ellipse cx="286" cy="216" rx="248" ry="220" fill="url(#glowBlue)" filter="url(#blurLarge)" />
    <ellipse cx="764" cy="756" rx="290" ry="266" fill="url(#glowPurple)" filter="url(#blurLarge)" />
    <ellipse cx="532" cy="96" rx="360" ry="180" fill="white" fill-opacity="0.06" filter="url(#blurLarge)" />
    <g filter="url(#blurSoft)" opacity="0.34">
      <rect x="248" y="224" width="140" height="576" rx="70" fill="url(#n)" />
      <rect x="636" y="224" width="140" height="576" rx="70" fill="url(#n)" />
      <path d="M400 348L624 680" stroke="url(#n)" stroke-width="150" stroke-linecap="round" />
    </g>
    <g>
      <rect x="248" y="224" width="140" height="576" rx="70" fill="url(#n)" />
      <rect x="636" y="224" width="140" height="576" rx="70" fill="url(#n)" />
      <path d="M400 348L624 680" stroke="url(#n)" stroke-width="150" stroke-linecap="round" />
    </g>
    <g opacity="0.2" filter="url(#blurSoft)">
      <ellipse cx="360" cy="314" rx="250" ry="210" fill="white" />
    </g>
    <g opacity="0.14" filter="url(#blurSoft)">
      <ellipse cx="674" cy="684" rx="240" ry="232" fill="#040812" />
    </g>
  </g>
</svg>
"""
    path.write_text(svg, encoding="utf-8")


def main() -> None:
    master = render_master_icon()
    transparent_mark = render_transparent_mark()
    compact_mark = render_compact_mark()
    save_png(MASTER_PNG_PATH, master, SIZE)
    save_png(TRANSPARENT_MARK_PNG_PATH, transparent_mark, SIZE)
    save_png(COMPACT_MARK_PNG_PATH, compact_mark, SIZE)
    save_rounded_preview(ROUNDED_PREVIEW_PNG_PATH, master, SIZE)
    write_master_svg(MASTER_SVG_PATH)
    save_android_icons(master)
    save_ios_icons(master)
    save_web_icons(master)


if __name__ == "__main__":
    main()
