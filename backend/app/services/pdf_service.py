"""Renders a diet plan as a PDF.

Drawn directly onto the canvas rather than built from flowables: the layout
is a fixed structure of hairline rules and columns, which is simpler to
place by hand than to configure a table engine into producing.

Colours match the app's light theme so an exported plan looks like it came
from NutriAI rather than from a report generator.
"""

from io import BytesIO

from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

from app.models.diet_plan import DietPlan

# The light palette, matching frontend/lib/app/theme/colors.dart.
PAPER = HexColor("#F2EFE6")
INK = HexColor("#1C1A15")
CHAR = HexColor("#4A4639")
MUTED = HexColor("#6B6555")
HAIR = HexColor("#CFC7B2")
TURMERIC = HexColor("#8A6318")
EMBER = HexColor("#9A3F15")

PAGE_WIDTH, PAGE_HEIGHT = A4
MARGIN = 48

# Reportlab's built-in faces. Archivo and IBM Plex Mono would need the .ttf
# files registered; Helvetica and Courier are close enough in role and keep
# the export dependency-free.
SANS = "Helvetica"
SANS_BOLD = "Helvetica-Bold"
MONO = "Courier"

SLOT_LABELS = {
    "breakfast": "BREAKFAST",
    "lunch": "LUNCH",
    "dinner": "DINNER",
    "snack": "SNACK",
}


class _Page:
    """Tracks the drawing cursor and starts a new page when space runs out."""

    def __init__(self, c: canvas.Canvas):
        self.c = c
        self.y = PAGE_HEIGHT - MARGIN
        self._background()

    def _background(self) -> None:
        self.c.setFillColor(PAPER)
        self.c.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, stroke=0, fill=1)

    def space(self, amount: float) -> None:
        self.y -= amount

    def ensure(self, needed: float) -> None:
        """Start a new page if `needed` points will not fit."""
        if self.y - needed < MARGIN:
            self.c.showPage()
            self.y = PAGE_HEIGHT - MARGIN
            self._background()

    def rule(self) -> None:
        self.c.setStrokeColor(HAIR)
        self.c.setLineWidth(0.5)
        self.c.line(MARGIN, self.y, PAGE_WIDTH - MARGIN, self.y)

    def text(
        self,
        value: str,
        *,
        font: str = SANS,
        size: float = 10,
        colour=INK,
        x: float | None = None,
        right: bool = False,
    ) -> None:
        self.c.setFont(font, size)
        self.c.setFillColor(colour)
        if right:
            self.c.drawRightString(PAGE_WIDTH - MARGIN, self.y, value)
        else:
            self.c.drawString(x if x is not None else MARGIN, self.y, value)

    def wrapped(
        self,
        value: str,
        *,
        x: float,
        width: float,
        font: str = SANS,
        size: float = 10,
        colour=INK,
        leading: float = 13,
    ) -> None:
        """Draws text broken to fit `width`, advancing the cursor."""
        self.c.setFont(font, size)
        self.c.setFillColor(colour)

        words = value.split()
        line = ""

        for word in words:
            candidate = f"{line} {word}".strip()
            if self.c.stringWidth(candidate, font, size) <= width:
                line = candidate
                continue
            self.c.drawString(x, self.y, line)
            self.y -= leading
            line = word

        if line:
            self.c.drawString(x, self.y, line)
            self.y -= leading


def _format_date(plan: DietPlan) -> str:
    return plan.plan_date.strftime("%A %d %B %Y")


def _macros(meal) -> str:
    parts = []
    if meal.protein_g is not None:
        parts.append(f"P {round(meal.protein_g)}g")
    if meal.carbs_g is not None:
        parts.append(f"C {round(meal.carbs_g)}g")
    if meal.fat_g is not None:
        parts.append(f"F {round(meal.fat_g)}g")
    return "   ".join(parts)


def render_plan(plan: DietPlan, *, name: str | None = None) -> bytes:
    """Return the plan as PDF bytes."""
    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=A4)
    c.setTitle(f"NutriAI plan - {plan.plan_date.isoformat()}")

    page = _Page(c)

    # Masthead
    page.text("NutriAI", font=SANS_BOLD, size=16)
    page.text(_format_date(plan).upper(), font=MONO, size=8, colour=MUTED, right=True)
    page.space(10)
    page.rule()
    page.space(28)

    page.text(
        f"Plan for {name}" if name else "Your plan",
        font=SANS_BOLD,
        size=22,
    )
    page.space(26)

    # Totals band
    page.rule()
    page.space(18)

    column = (PAGE_WIDTH - 2 * MARGIN) / 3
    labels = [
        ("PLANNED", f"{plan.total_calories}", "kcal"),
        ("TARGET", f"{plan.target_calories}", "kcal"),
        ("PROTEIN", f"{round(plan.total_protein_g)}", "g"),
    ]

    for i, (label, value, unit) in enumerate(labels):
        x = MARGIN + i * column
        c.setFont(MONO, 7.5)
        c.setFillColor(MUTED)
        c.drawString(x, page.y, label)

        c.setFont(MONO, 17)
        c.setFillColor(INK)
        c.drawString(x, page.y - 22, value)

        width = c.stringWidth(value, MONO, 17)
        c.setFont(MONO, 9)
        c.setFillColor(MUTED)
        c.drawString(x + width + 4, page.y - 22, unit)

    page.space(34)
    page.rule()
    page.space(24)

    # Rationale
    if plan.rationale:
        page.wrapped(
            plan.rationale,
            x=MARGIN,
            width=PAGE_WIDTH - 2 * MARGIN,
            size=10.5,
            colour=CHAR,
            leading=14,
        )
        page.space(14)

    page.text("MEALS", font=MONO, size=7.5, colour=MUTED)
    page.space(12)

    # Meals
    for meal in plan.meals:
        # Rough height check before drawing, so a meal is never split.
        page.ensure(84)
        page.rule()
        page.space(18)

        slot_x = MARGIN
        body_x = MARGIN + 78
        body_width = PAGE_WIDTH - MARGIN - body_x - 48

        top = page.y

        c.setFont(MONO, 7.5)
        c.setFillColor(CHAR)
        c.drawString(slot_x, top, SLOT_LABELS.get(meal.slot, meal.slot.upper()))

        if meal.time_hint:
            c.setFont(MONO, 8)
            c.setFillColor(MUTED)
            c.drawString(slot_x, top - 11, meal.time_hint)

        c.setFont(MONO, 12)
        c.setFillColor(INK)
        c.drawRightString(PAGE_WIDTH - MARGIN, top, str(meal.calories))

        page.wrapped(
            meal.name, x=body_x, width=body_width, font=SANS_BOLD, size=11
        )

        if meal.portion:
            page.wrapped(
                meal.portion,
                x=body_x,
                width=body_width,
                size=9,
                colour=MUTED,
                leading=11,
            )

        macros = _macros(meal)
        if macros:
            page.space(3)
            page.text(macros, font=MONO, size=8, colour=MUTED, x=body_x)
            page.space(11)

        if meal.substitution:
            page.wrapped(
                f"Swap: {meal.substitution}",
                x=body_x,
                width=body_width,
                size=9,
                colour=TURMERIC,
                leading=11,
            )

        page.space(10)

    page.ensure(60)
    page.rule()
    page.space(16)

    page.wrapped(
        "Portions are a starting point, not a prescription. Adjust to what is "
        "available and how hungry you are. NutriAI gives general nutrition "
        "guidance and does not replace advice from a doctor or registered "
        "dietitian.",
        x=MARGIN,
        width=PAGE_WIDTH - 2 * MARGIN,
        size=8.5,
        colour=MUTED,
        leading=11,
    )

    c.showPage()
    c.save()
    return buffer.getvalue()