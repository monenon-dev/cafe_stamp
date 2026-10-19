"""모아 스탬프 앱 아이콘·스플래시 이미지 생성.

에스프레소 바탕 위에 살짝 기울어진 캐러멜 커피 도장을 그린다.
사용: python tool/make_icon.py  (assets/branding/ 에 PNG 생성)
"""
from pathlib import Path

from PIL import Image, ImageDraw

ESPRESSO = (0x3B, 0x2A, 0x21, 255)
CARAMEL = (0xC8, 0x92, 0x5E, 255)
LATTE = (0xEF, 0xE3, 0xD3, 255)
OUT = Path(__file__).resolve().parent.parent / "assets" / "branding"
SS = 4  # 슈퍼샘플링 배율 (부드러운 가장자리)


def stamp(size: int, scale: float) -> Image.Image:
    """투명 바탕에 도장 모티프. scale은 캔버스 대비 도장 지름 비율."""
    n = size * SS
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = n / 2
    r = n * scale / 2

    # 바깥 테두리 + 안쪽 잉크 원
    ring = r * 0.07
    d.ellipse([c - r, c - r, c + r, c + r], outline=CARAMEL, width=int(ring))
    ri = r - ring * 2.2
    d.ellipse([c - ri, c - ri, c + ri, c + ri], fill=CARAMEL)

    # 커피잔 (에스프레소 색으로 잉크를 파낸 모양)
    u = ri / 8.2
    cx, cy = c - u * 0.7, c - u * 0.4
    body = [cx - u * 4.2, cy - u * 3.0, cx + u * 3.2, cy + u * 2.6]
    d.rounded_rectangle(body, radius=u * 1.6, fill=ESPRESSO)
    d.rectangle([body[0], body[1], body[2], body[1] + u * 1.6], fill=ESPRESSO)
    # 손잡이
    hw = u * 0.9
    d.ellipse([cx + u * 1.9, cy - u * 1.9, cx + u * 5.5, cy + u * 1.6], outline=ESPRESSO, width=int(hw))
    # 잔 받침
    d.rounded_rectangle([cx - u * 5.4, cy + u * 3.3, cx + u * 4.4, cy + u * 4.3], radius=u * 0.5, fill=ESPRESSO)
    # 커피 수면 (라테 크림)
    d.rounded_rectangle([cx - u * 3.4, cy - u * 2.4, cx + u * 2.4, cy - u * 1.5], radius=u * 0.45, fill=LATTE)

    img = img.rotate(8, resample=Image.BICUBIC, center=(c, c))
    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    size = 1024

    # iOS·기본 아이콘: 꽉 찬 에스프레소 정사각형 (투명 없음)
    full = Image.new("RGBA", (size, size), ESPRESSO)
    full.alpha_composite(stamp(size, 0.68))
    full.convert("RGB").save(OUT / "icon.png")

    # Android 적응형 아이콘 전경: 가운데 안전 영역(약 66%) 안에 들어오게 작게
    stamp(size, 0.50).save(OUT / "icon_foreground.png")

    # 스플래시 로고: 투명 바탕
    stamp(size, 0.62).save(OUT / "splash_logo.png")
    print("saved:", *sorted(p.name for p in OUT.glob("*.png")))


if __name__ == "__main__":
    main()
