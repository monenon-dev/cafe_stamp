"""크몽 포트폴리오용 홍보 이미지 생성.

marketing/screens/ 의 에뮬레이터 스크린샷을 기기 틀에 넣고 제목·설명을 얹어
marketing/promo/ 에 4:3 이미지(1304x978, 크몽 대표 이미지 652x488의 2배)를 만든다.

사용: python tool/make_promo.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SCREENS = ROOT / "marketing" / "screens"
OUT = ROOT / "marketing" / "promo"
FONTS = ROOT / "assets" / "fonts" / "pretendard"

W, H = 1304, 978

ESPRESSO = (0x3B, 0x2A, 0x21)
MOCHA = (0x8A, 0x5A, 0x3B)
CARAMEL = (0xC8, 0x92, 0x5E)
LATTE = (0xEF, 0xE3, 0xD3)
IVORY = (0xF7, 0xF1, 0xE8)
BEZEL = (0x1E, 0x16, 0x12)


def font(weight: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"Pretendard-{weight}.otf"), size)


def screen(name: str) -> Image.Image:
    return Image.open(SCREENS / name).convert("RGB")


def phone(shot: Image.Image, height: int) -> Image.Image:
    """스크린샷을 둥근 기기 틀에 넣고 그림자를 붙인다."""
    sw = int(shot.width * height / shot.height)
    shot = shot.resize((sw, height), Image.LANCZOS)
    bezel = max(8, sw // 34)
    fw, fh = sw + bezel * 2, height + bezel * 2
    radius = int(fw * 0.11)

    frame = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle([0, 0, fw - 1, fh - 1], radius, fill=BEZEL)
    mask = Image.new("L", (sw, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, height - 1], radius - bezel, fill=255)
    frame.paste(shot, (bezel, bezel), mask)

    pad = 40
    out = Image.new("RGBA", (fw + pad * 2, fh + pad * 2), (0, 0, 0, 0))
    shadow = Image.new("L", out.size, 0)
    ImageDraw.Draw(shadow).rounded_rectangle([pad, pad + 12, pad + fw, pad + fh + 12], radius, fill=110)
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    out.paste((0, 0, 0, 255), (0, 0), shadow)
    out.alpha_composite(frame, (pad, pad))
    return out


def place_phones(canvas: Image.Image, names: list[str], x0: int, x1: int, top: int, max_h: int, gap: int) -> None:
    """[x0, x1] 구간 안에 들어가도록 높이를 정해 가운데 정렬로 나란히 놓는다."""
    shots = [screen(n) for n in names]
    ratio = shots[0].width / shots[0].height
    height = max_h
    while height > 200:
        phones = [phone(s, height) for s in shots]
        total = sum(p.width for p in phones) + gap * (len(phones) - 1)
        if total <= x1 - x0:
            break
        height -= 20
    x = x0 + (x1 - x0 - total) // 2
    for p in phones:
        canvas.alpha_composite(p, (x, top))
        x += p.width + gap


def text_block(draw: ImageDraw.ImageDraw, x: int, y: int, label: str, title: str, body: str, dark: bool) -> None:
    fg = LATTE if dark else ESPRESSO
    sub = (*LATTE, 200) if dark else MOCHA
    draw.text((x, y), label, font=font("SemiBold", 22), fill=CARAMEL if dark else MOCHA)
    draw.multiline_text((x, y + 40), title, font=font("Bold", 56), fill=fg, spacing=14)
    title_h = draw.multiline_textbbox((x, y + 40), title, font=font("Bold", 56), spacing=14)[3]
    draw.multiline_text((x, title_h + 24), body, font=font("Regular", 26), fill=sub, spacing=12)


def feature_slide(file: str, label: str, title: str, body: str, shots: list[str], dark: bool) -> None:
    canvas = Image.new("RGBA", (W, H), (*(ESPRESSO if dark else IVORY), 255))
    draw = ImageDraw.Draw(canvas)
    if len(shots) <= 2:
        # 왼쪽 글, 오른쪽 기기
        text_block(draw, 72, 110, label, title, body, dark)
        place_phones(canvas, shots, x0=520, x1=W - 20, top=90, max_h=760, gap=-50)
    else:
        # 위쪽 글(제목 한 줄), 아래쪽 기기 3대. 기기 아랫부분은 화면 밖으로 살짝 넘긴다.
        one_line = " ".join(title.splitlines())
        text_block(draw, 72, 64, label, one_line, body, dark)
        place_phones(canvas, shots, x0=40, x1=W - 40, top=372, max_h=640, gap=-40)
    canvas.convert("RGB").save(OUT / file)


def main_slide() -> None:
    canvas = Image.new("RGBA", (W, H), (*ESPRESSO, 255))
    draw = ImageDraw.Draw(canvas)

    icon = Image.open(ROOT / "assets" / "branding" / "icon.png").convert("RGBA").resize((112, 112), Image.LANCZOS)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, 111, 111], 26, fill=255)
    canvas.paste(icon, (80, 150), mask)

    draw.text((80, 300), "FLUTTER APP PORTFOLIO", font=font("SemiBold", 22), fill=CARAMEL)
    draw.text((80, 338), "모아 스탬프", font=font("Bold", 84), fill=LATTE)
    draw.multiline_text(
        (80, 452),
        "카페 스탬프 · 쿠폰 · 멤버십 앱\n기획부터 디자인, 개발까지",
        font=font("Regular", 30),
        fill=(*LATTE, 210),
        spacing=14,
    )

    chips = ["Android · iOS · Web", "Material 3", "Riverpod", "테스트 32개"]
    x, y = 80, 590
    for chip in chips:
        f = font("SemiBold", 22)
        w = int(draw.textlength(chip, font=f)) + 36
        if x + w > 470:
            x, y = 80, y + 60
        draw.rounded_rectangle([x, y, x + w, y + 46], 23, fill=(*MOCHA, 255))
        draw.text((x + 18, y + 10), chip, font=f, fill=LATTE)
        x += w + 12

    place_phones(canvas, ["04_home.png", "05_stamp.png"], x0=500, x1=W - 20, top=70, max_h=780, gap=-50)
    canvas.convert("RGB").save(OUT / "01_main.png")


def tech_slide() -> None:
    canvas = Image.new("RGBA", (W, H), (*IVORY, 255))
    draw = ImageDraw.Draw(canvas)
    draw.text((72, 96), "HOW IT'S BUILT", font=font("SemiBold", 22), fill=MOCHA)
    draw.text((72, 136), "이렇게 만들었어요", font=font("Bold", 56), fill=ESPRESSO)

    items = [
        ("Flutter 3 · Material 3", "Android · iOS · Web을 한 코드로"),
        ("Riverpod 상태 관리", "적립 규칙·연타 방지·쿠폰 발급을 화면과 분리"),
        ("go_router 내비게이션", "탭별 화면 기록 유지, 온보딩·멤버십 전체 화면"),
        ("로컬 저장 · 샘플 데이터", "shared_preferences, 첫 실행 때만 예시 기록"),
        ("디자인 토큰", "색·간격·모서리를 한곳에서 바꾸면 앱 전체에 반영"),
        ("품질 관리", "자동 테스트 32개 · 정적 분석 경고 0건"),
    ]
    col_w, row_h = 560, 200
    for i, (head, desc) in enumerate(items):
        cx = 72 + (i % 2) * (col_w + 40)
        cy = 260 + (i // 2) * row_h
        draw.rounded_rectangle([cx, cy, cx + col_w, cy + row_h - 30], 28, fill=(255, 252, 247))
        draw.ellipse([cx + 28, cy + 34, cx + 44, cy + 50], fill=CARAMEL)
        draw.text((cx + 60, cy + 24), head, font=font("Bold", 30), fill=ESPRESSO)
        draw.text((cx + 60, cy + 76), desc, font=font("Regular", 23), fill=MOCHA)
    canvas.convert("RGB").save(OUT / "06_tech.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    main_slide()
    feature_slide(
        "02_stamp.png",
        "STAMP",
        "한 잔마다\n도장 쾅",
        "멤버십 QR을 보여 주면 도장이 찍히고, 10개를 채우면\n무료 음료 쿠폰이 자동으로 발급돼요.",
        ["06_membership_qr.png", "05_stamp.png", "07_coupon_issued.png"],
        dark=False,
    )
    feature_slide(
        "03_coupon.png",
        "COUPON",
        "티켓처럼 생긴\n쿠폰함",
        "사용 가능 · 사용 완료 · 만료를 나눠 보고,\n매장에서 바로 쓰는 바코드까지.",
        ["08_coupons.png", "09_coupon_detail.png"],
        dark=True,
    )
    feature_slide(
        "04_onboarding.png",
        "ONBOARDING",
        "처음 여는\n순간부터",
        "스플래시에서 이어지는 3장의 소개로\n앱의 핵심을 먼저 보여 줘요.",
        ["01_onboarding_1.png", "02_onboarding_2.png", "03_onboarding_3.png"],
        dark=True,
    )
    feature_slide(
        "05_home_profile.png",
        "HOME & PROFILE",
        "한눈에 보는\n내 커피 생활",
        "적립 진행률, 만료 임박 쿠폰,\n회원 등급과 이용 통계까지.",
        ["04_home.png", "10_profile.png"],
        dark=False,
    )
    tech_slide()
    print("saved:", *sorted(p.name for p in OUT.glob("*.png")))


if __name__ == "__main__":
    main()
