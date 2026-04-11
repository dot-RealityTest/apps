  from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


PAGE_WIDTH, PAGE_HEIGHT = A4
OUTPUT_PATH = "output/pdf/breakpoint-showcase.pdf"


def draw_header(c: canvas.Canvas, title: str, subtitle: str) -> None:
    c.setFillColor(colors.HexColor("#0E1116"))
    c.rect(0, PAGE_HEIGHT - 72 * mm, PAGE_WIDTH, 72 * mm, stroke=0, fill=1)

    c.setFillColor(colors.HexColor("#4DD0E1"))
    c.rect(20 * mm, PAGE_HEIGHT - 52 * mm, 34 * mm, 7 * mm, stroke=0, fill=1)

    c.setFillColor(colors.HexColor("#F7FAFC"))
    c.setFont("Helvetica-Bold", 30)
    c.drawString(20 * mm, PAGE_HEIGHT - 38 * mm, title)

    c.setFont("Helvetica", 12)
    c.setFillColor(colors.HexColor("#C7D2E1"))
    c.drawString(20 * mm, PAGE_HEIGHT - 44.5 * mm, subtitle)


def draw_card(c: canvas.Canvas, x: float, y_top: float, w: float, h: float, title: str, body: str, accent: str) -> None:
    c.setFillColor(colors.HexColor("#F8FAFC"))
    c.roundRect(x, y_top - h, w, h, 4 * mm, stroke=0, fill=1)
    c.setStrokeColor(colors.HexColor("#E2E8F0"))
    c.setLineWidth(1)
    c.roundRect(x, y_top - h, w, h, 4 * mm, stroke=1, fill=0)

    c.setFillColor(colors.HexColor(accent))
    c.rect(x, y_top - 6 * mm, w, 3 * mm, stroke=0, fill=1)

    c.setFillColor(colors.HexColor("#0F172A"))
    c.setFont("Helvetica-Bold", 13)
    c.drawString(x + 5 * mm, y_top - 14 * mm, title)

    styles = getSampleStyleSheet()
    p_style = ParagraphStyle(
        "card",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=10,
        leading=13,
        textColor=colors.HexColor("#334155"),
    )
    p = Paragraph(body, p_style)
    p.wrapOn(c, w - 10 * mm, h - 22 * mm)
    p.drawOn(c, x + 5 * mm, y_top - h + 5 * mm)


def draw_page_one(c: canvas.Canvas) -> None:
    draw_header(
        c,
        "BreakPoint Showcase",
        "Emergency context preservation for developers and knowledge workers",
    )

    c.setFont("Helvetica-Bold", 16)
    c.setFillColor(colors.HexColor("#0F172A"))
    c.drawString(20 * mm, PAGE_HEIGHT - 86 * mm, "Product Snapshot")

    c.setFont("Helvetica", 11)
    c.setFillColor(colors.HexColor("#334155"))
    c.drawString(
        20 * mm,
        PAGE_HEIGHT - 93 * mm,
        "One hotkey captures machine state, generates an AI action plan, and syncs to Apple Notes.",
    )

    card_w = (PAGE_WIDTH - 50 * mm) / 2
    x1 = 20 * mm
    x2 = x1 + card_w + 10 * mm

    draw_card(
        c,
        x1,
        PAGE_HEIGHT - 102 * mm,
        card_w,
        56 * mm,
        "Core Outcome",
        "BreakPoint turns chaotic multi-window sessions into a clear handoff in one click. It preserves active context before interruptions and helps users restart quickly from mobile or desktop.",
        "#2563EB",
    )

    draw_card(
        c,
        x2,
        PAGE_HEIGHT - 102 * mm,
        card_w,
        56 * mm,
        "How Users Trigger It",
        "- Left-click menu bar icon<br/>- Global hotkey: Cmd + Shift + Escape<br/>- Right-click menu: Doom's Moment",
        "#0EA5A4",
    )

    draw_card(
        c,
        x1,
        PAGE_HEIGHT - 162 * mm,
        card_w,
        68 * mm,
        "Data Sources Captured",
        "- Frontmost app, running apps, and window titles<br/>- Clipboard and on-screen OCR text<br/>- Local knowledge graph context<br/>- Pieces OS workstream memory",
        "#7C3AED",
    )

    draw_card(
        c,
        x2,
        PAGE_HEIGHT - 162 * mm,
        card_w,
        68 * mm,
        "AI Strategy",
        "Primary generation uses Pieces QGPT when enabled. If unavailable, failing, or refusing, BreakPoint auto-falls back to Ollama so users always receive a usable output.",
        "#DC2626",
    )


def draw_page_two(c: canvas.Canvas) -> None:
    draw_header(
        c,
        "Modes, UX, and Architecture",
        "A practical view of how BreakPoint balances speed, structure, and resilience",
    )

    c.setFont("Helvetica-Bold", 16)
    c.setFillColor(colors.HexColor("#0F172A"))
    c.drawString(20 * mm, PAGE_HEIGHT - 86 * mm, "Generation Modes")

    mode_w = (PAGE_WIDTH - 55 * mm) / 3
    top = PAGE_HEIGHT - 95 * mm

    draw_card(
        c,
        20 * mm,
        top,
        mode_w,
        58 * mm,
        "Normal",
        "1000-1500 words.<br/>Balanced and thorough context capture with priority markers for urgent vs later actions.",
        "#2563EB",
    )

    draw_card(
        c,
        20 * mm + mode_w + 7.5 * mm,
        top,
        mode_w,
        58 * mm,
        "ADHD",
        "600-900 words.<br/>Scannable, short lines with text priority tags for quick phone-friendly execution.",
        "#EA580C",
    )

    draw_card(
        c,
        20 * mm + (mode_w + 7.5 * mm) * 2,
        top,
        mode_w,
        58 * mm,
        "Code",
        "1200-1800 words.<br/>Developer-centric output with file paths, commands, debugging context, and architecture notes.",
        "#16A34A",
    )

    draw_card(
        c,
        20 * mm,
        PAGE_HEIGHT - 160 * mm,
        81 * mm,
        74 * mm,
        "UX Signals",
        "- Menu bar icon pulses while generating<br/>- Status popover supports idle, loading, success, and error states<br/>- Success includes saved filename and auto-dismisses after 5 seconds",
        "#0891B2",
    )

    draw_card(
        c,
        107 * mm,
        PAGE_HEIGHT - 160 * mm,
        82 * mm,
        74 * mm,
        "Output + Distribution",
        "- Timestamped markdown snapshots in export directory<br/>- Apple Notes export into Doom Moments folder<br/>- Task sections become native checklist items for mobile follow-through",
        "#9333EA",
    )

    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(colors.HexColor("#0F172A"))
    c.drawString(20 * mm, 34 * mm, "Architecture at a Glance")

    c.setFont("Helvetica", 10.5)
    c.setFillColor(colors.HexColor("#334155"))
    c.drawString(20 * mm, 28 * mm, "SwiftUI menu bar app | Carbon hotkey | Vision OCR | SQLite3 | AppleScript Notes export")
    c.drawString(20 * mm, 23 * mm, "Core orchestrator: DoomsMomentService | Degrades gracefully when optional sources are unavailable")


def add_footer(c: canvas.Canvas, page_number: int) -> None:
    c.setStrokeColor(colors.HexColor("#CBD5E1"))
    c.setLineWidth(0.6)
    c.line(20 * mm, 14 * mm, PAGE_WIDTH - 20 * mm, 14 * mm)

    c.setFillColor(colors.HexColor("#64748B"))
    c.setFont("Helvetica", 9)
    c.drawString(20 * mm, 9 * mm, "BreakPoint product showcase")
    c.drawRightString(PAGE_WIDTH - 20 * mm, 9 * mm, f"Page {page_number}")


def build_pdf(path: str) -> None:
    c = canvas.Canvas(path, pagesize=A4)

    draw_page_one(c)
    add_footer(c, 1)
    c.showPage()

    draw_page_two(c)
    add_footer(c, 2)
    c.showPage()

    c.save()


if __name__ == "__main__":
    build_pdf(OUTPUT_PATH)
    print(f"Wrote {OUTPUT_PATH}")
