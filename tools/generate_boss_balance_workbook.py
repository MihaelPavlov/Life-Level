#!/usr/bin/env python3
"""Generate the Life-Level boss/encounter balancing workbook via LibreOffice UNO."""

from __future__ import annotations

import os
import subprocess
import sys
import time
from pathlib import Path

sys.path.append("/usr/lib/python3/dist-packages")
import uno  # type: ignore  # noqa: E402
from com.sun.star.beans import PropertyValue  # type: ignore  # noqa: E402


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "balance" / "LifeLevel_Boss_Encounter_Balance_v2.xlsx"
SOCKET = "lifelevel_balance_sheet"
LO_PROFILE = "/tmp/lifelevel-lo-profile"


def prop(name: str, value: object) -> PropertyValue:
    p = PropertyValue()
    p.Name = name
    p.Value = value
    return p


def connect():
    local_ctx = uno.getComponentContext()
    resolver = local_ctx.ServiceManager.createInstanceWithContext(
        "com.sun.star.bridge.UnoUrlResolver", local_ctx
    )
    try:
        return resolver.resolve(
            f"uno:pipe,name={SOCKET};urp;StarOffice.ComponentContext"
        )
    except Exception:
        lo_env = os.environ.copy()
        lo_env.update({
            "XDG_CONFIG_HOME": "/tmp/lifelevel-xdg-config",
            "XDG_CACHE_HOME": "/tmp/lifelevel-xdg-cache",
            "XDG_RUNTIME_DIR": "/tmp/lifelevel-xdg-runtime",
        })
        Path(lo_env["XDG_RUNTIME_DIR"]).mkdir(parents=True, exist_ok=True)
        subprocess.Popen(
            [
                "soffice",
                "--headless",
                "--nologo",
                "--nodefault",
                "--nofirststartwizard",
                f"-env:UserInstallation=file://{LO_PROFILE}",
                f"--accept=pipe,name={SOCKET};urp;StarOffice.ServiceManager",
            ],
            env=lo_env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        for _ in range(50):
            time.sleep(0.2)
            try:
                return resolver.resolve(
                    f"uno:pipe,name={SOCKET};urp;StarOffice.ComponentContext"
                )
            except Exception:
                pass
        raise RuntimeError("Could not connect to headless LibreOffice")


def set_row(sheet, row: int, values: list[object]) -> None:
    for col, value in enumerate(values):
        cell = sheet.getCellByPosition(col, row)
        if isinstance(value, str) and value.startswith("="):
            cell.Formula = value
        elif isinstance(value, (int, float)):
            cell.Value = float(value)
        else:
            cell.String = str(value)


def style_range(sheet, address: str, *, bg=None, color=None, bold=None, size=None):
    cells = sheet.getCellRangeByName(address)
    if bg is not None:
        cells.CellBackColor = bg
    if color is not None:
        cells.CharColor = color
    if bold is not None:
        cells.CharWeight = 150.0 if bold else 100.0
    if size is not None:
        cells.CharHeight = float(size)


def width(sheet, column: str, value: int) -> None:
    sheet.getColumns().getByName(column).Width = value


def build_workbook() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    ctx = connect()
    desktop = ctx.ServiceManager.createInstanceWithContext(
        "com.sun.star.frame.Desktop", ctx
    )
    doc = desktop.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
    sheets = doc.getSheets()
    sheets.getByIndex(0).Name = "README"
    for name in ("Settings", "Gear Loadout", "Talent Loadout", "Player Builds", "Activity Scenarios", "Boss Balance"):
        sheets.insertNewByName(name, sheets.getCount())

    navy, blue, pale_blue = 0x17233C, 0x2684FF, 0xDDEBFF
    green, pale_green = 0x22A06B, 0xDDF4E8
    orange, pale_orange = 0xE67E22, 0xFDEBD0
    gray, white, red = 0xE9EDF3, 0xFFFFFF, 0xC9372C

    # README
    s = sheets.getByName("README")
    set_row(s, 0, ["Life-Level Boss & Encounter Balance Workbook"])
    s.getCellRangeByName("A1:H1").merge(True)
    style_range(s, "A1:H1", bg=navy, color=white, bold=True, size=18)
    rows = [
        ["Purpose", "Balance every boss using complete player builds: level, five stats, six equipped gear slots, all talent levels, previous boss victories, and actual workouts."],
        ["Blue cells", "Designer inputs. Change these to test an encounter."],
        ["Green cells", "Calculated outputs."],
        ["Orange cells", "Implemented Combat V2 incoming-damage values."],
        ["Current activity damage", "INT((calories × 0.5 + minutes + distanceKm × 3) × activity multiplier), then rounded after player damage modifiers."],
        ["Current world boss HP", "Expected post-armor median hit × target turns (8 in chapters 1-4, 10 in 5-10, 12 in 11-15)."],
        ["Current guild raid HP", "Base boss HP × (0.75 + clamp(guild size, 1, 20) × 0.35)."],
        ["Armor", "Mitigation = Armor / (Armor + K); damage taken = raw damage × K / (Armor + K). Implemented for personal bosses and guild outgoing damage."],
        ["Hits survived", "Player HP / damage per hit. This is an analysis metric; games normally calculate damage, not a hit counter."],
        ["Workflow", "1) Edit Gear Loadout and Talent Loadout. 2) Edit base stats and previous victories in Player Builds. 3) Tune actual workouts. 4) Review Boss Balance."],
        ["Code references", "BossService.CalculateDamageFromActivity; BossCombatCalculator; BossBalanceCalculator; WorldBossBridgeService; WorldSeedData."],
    ]
    for i, row in enumerate(rows, 2):
        set_row(s, i, row)
    style_range(s, "A3:A13", bold=True, bg=gray)
    s.getCellRangeByName("B3:B13").IsTextWrapped = True
    width(s, "A", 5200)
    width(s, "B", 21000)
    s.getRows().OptimalHeight = True
    s.getCellRangeByName("A3:B13").TableBorder = s.getCellRangeByName("A3:B13").TableBorder

    # Settings
    s = sheets.getByName("Settings")
    set_row(s, 0, ["Global balance assumptions", "Value", "Notes"])
    style_range(s, "A1:C1", bg=navy, color=white, bold=True)
    settings = [
        ["Armor constant K", 100, "Higher K makes armor weaker."],
        ["Expected raw damage / workout", 250, "Median tuning hit before player multiplier, boss bonus, and boss armor."],
        ["Player damage multiplier", 1.0, "Current combat-stat multiplier."],
        ["Boss-active bonus", 0, "Percent talent bonus."],
        ["Expected workouts / day", 0.75, "Used to estimate calendar days."],
        ["Default player HP", 440, "For proposed incoming boss attacks."],
        ["Default player armor", 0, "For proposed incoming boss attacks."],
        ["Default boss raw hit", 50, "For proposed incoming boss attacks."],
        ["Recovery hours", 12, "Workouts still earn rewards while personal-boss attacks are paused."],
        ["Guild size", 4, "Used on the guild calculator below."],
        ["Guild HP multiplier", "=0.75+MIN(20;MAX(1;B11))*0.35", "Matches current backend."],
        ["Guild reward multiplier", "=1+(B12-1)*0.35", "Matches current backend."],
    ]
    for i, row in enumerate(settings, 1):
        set_row(s, i, row)
    style_range(s, "B2:B11", bg=pale_blue)
    style_range(s, "B12:B13", bg=pale_green)
    s.getCellRangeByName("B2:B13").NumberFormat = 2
    width(s, "A", 6800); width(s, "B", 3800); width(s, "C", 12500)
    s.getCellRangeByName("C2:C13").IsTextWrapped = True

    build_rows = [
        (1, "Forest Warden", 1), (2, "Tide Sovereign", 8), (3, "Stone Titan", 15),
        (4, "Molten King", 25), (5, "Hoarfrost Queen", 32), (6, "Dune Pharaoh", 38),
        (7, "Bramble Lord", 44), (8, "Pearl Leviathan", 50), (9, "Storm Sovereign", 56),
        (10, "Cinder Archon", 62), (11, "Deepfrost Wyrm", 68), (12, "Sand Kaiser", 72),
        (13, "Thornwarden", 76), (14, "Maw of the Deep", 80), (15, "Worldflame", 85),
    ]

    # One editable six-slot equipment loadout for every expected boss-level build.
    s = sheets.getByName("Gear Loadout")
    set_row(s, 0, ["Profile", "Boss", "Slot", "Equipped item", "Equipped? (1/0)", "STR", "AGI", "END", "FLX", "STA", "XP bonus %"])
    style_range(s, "A1:K1", bg=navy, color=white, bold=True)
    gear_row = 2
    for profile, boss, _level in build_rows:
        for slot in ("Head", "Chest", "Hands", "Feet", "Accessory1", "Legs"):
            set_row(s, gear_row - 1, [profile, boss, slot, "", 0, 0, 0, 0, 0, 0, 0])
            gear_row += 1
    style_range(s, f"D2:K{gear_row-1}", bg=pale_blue)
    for col, val in zip("ABCDEFGHIJK", [2400, 4700, 3200, 6200, 3500, 2400, 2400, 2400, 2400, 2400, 3000]): width(s, col, val)

    # Full v1 talent catalog. Non-combat talents remain visible but contribute zero to boss damage.
    talent_defs = [
        ("Iron Grip", "StatStrength", 1), ("Deep Lungs", "StatEndurance", 1),
        ("Fast Twitch", "StatAgility", 1), ("Loose Joints", "StatFlexibility", 1),
        ("Second Engine", "StatStamina", 1), ("Focused Training", "ActivityXpPct", 1),
        ("Morning Momentum", "MorningXpPct", 2.5), ("Runner's High", "CardioXpPct", 1),
        ("Iron Discipline", "StrengthStyleXpPct", 1), ("Quest Zeal", "QuestXpPct", 2),
        ("Second Wind", "SecondWind", 1), ("Steel Resolve", "ComebackXpPct", 5),
        ("Shield Craft", "ShieldPerLevel", 1), ("Direct Hit", "BossDamagePct", 2),
        ("Boss Instinct", "BossActiveDamagePct", 2), ("Fair Exchange", "DropChancePct", 1),
    ]
    s = sheets.getByName("Talent Loadout")
    set_row(s, 0, ["Profile", "Boss", "Talent", "Effect type", "Per-level value", "Talent level (0-10)", "Total effect", "Affects boss damage?"])
    style_range(s, "A1:H1", bg=navy, color=white, bold=True)
    talent_row = 2
    for profile, boss, _level in build_rows:
        for name, effect, per_level in talent_defs:
            affects = "Yes" if effect.startswith("Stat") or effect in ("BossDamagePct", "BossActiveDamagePct") else "No"
            set_row(s, talent_row - 1, [profile, boss, name, effect, per_level, 0, f"=E{talent_row}*F{talent_row}", affects])
            talent_row += 1
    style_range(s, f"F2:F{talent_row-1}", bg=pale_blue)
    style_range(s, f"G2:G{talent_row-1}", bg=pale_green)
    for col, val in zip("ABCDEFGH", [2400, 4700, 5200, 5200, 3400, 3800, 3200, 3900]): width(s, col, val)

    # Complete backend-equivalent combat-stat derivation for every boss-level profile.
    s = sheets.getByName("Player Builds")
    build_headers = ["Profile", "Boss", "Level", "Base STR", "Base AGI", "Base END", "Base FLX", "Base STA", "Previous boss victories",
        "Gear STR", "Gear AGI", "Gear END", "Gear FLX", "Gear STA", "Talent STR", "Talent AGI", "Talent END", "Talent FLX", "Talent STA",
        "Boss damage %", "Boss-active damage %", "Effective STR", "Effective AGI", "Effective END", "Effective FLX", "Effective STA",
        "Attack", "Defense", "Health", "Power", "Damage multiplier", "Selected workout damage", "Final boss damage/workout"]
    set_row(s, 0, build_headers)
    style_range(s, "A1:AG1", bg=navy, color=white, bold=True)
    for row, (profile, boss, level) in enumerate(build_rows, 2):
        # Baseline stats are explicit editable assumptions, not a claim that level automatically grants these values.
        base_str, base_agi = round(level * 0.5), round(level * 0.6)
        base_end, base_flx, base_sta = round(level * 0.7), round(level * 0.3), round(level * 0.5)
        gr = "'Gear Loadout'"
        tr = "'Talent Loadout'"
        values = [profile, boss, level, base_str, base_agi, base_end, base_flx, base_sta, max(0, profile - 1),
            f"=SUMPRODUCT(({gr}.A$2:A$91=A{row})*{gr}.F$2:F$91*{gr}.E$2:E$91)",
            f"=SUMPRODUCT(({gr}.A$2:A$91=A{row})*{gr}.G$2:G$91*{gr}.E$2:E$91)",
            f"=SUMPRODUCT(({gr}.A$2:A$91=A{row})*{gr}.H$2:H$91*{gr}.E$2:E$91)",
            f"=SUMPRODUCT(({gr}.A$2:A$91=A{row})*{gr}.I$2:I$91*{gr}.E$2:E$91)",
            f"=SUMPRODUCT(({gr}.A$2:A$91=A{row})*{gr}.J$2:J$91*{gr}.E$2:E$91)",
            f'=SUMIFS({tr}.G$2:G$241;{tr}.A$2:A$241;A{row};{tr}.D$2:D$241;"StatStrength")',
            f'=SUMIFS({tr}.G$2:G$241;{tr}.A$2:A$241;A{row};{tr}.D$2:D$241;"StatAgility")',
            f'=SUMIFS({tr}.G$2:G$241;{tr}.A$2:A$241;A{row};{tr}.D$2:D$241;"StatEndurance")',
            f'=SUMIFS({tr}.G$2:G$241;{tr}.A$2:A$241;A{row};{tr}.D$2:D$241;"StatFlexibility")',
            f'=SUMIFS({tr}.G$2:G$241;{tr}.A$2:A$241;A{row};{tr}.D$2:D$241;"StatStamina")',
            f'=SUMIFS({tr}.G$2:G$241;{tr}.A$2:A$241;A{row};{tr}.D$2:D$241;"BossDamagePct")',
            f'=SUMIFS({tr}.G$2:G$241;{tr}.A$2:A$241;A{row};{tr}.D$2:D$241;"BossActiveDamagePct")',
            f"=D{row}+J{row}+O{row}", f"=E{row}+K{row}+P{row}", f"=F{row}+L{row}+Q{row}", f"=G{row}+M{row}+R{row}", f"=H{row}+N{row}+S{row}",
            f"=ROUND((10+2*V{row}+W{row})*(1+T{row}/100);0)", f"=ROUND(5+W{row}+1.5*Y{row};0)", f"=ROUND(50+8*Z{row}+4*X{row};0)",
            f"=ROUND(100+20*C{row}+3*AA{row}+3*AB{row}+0.6*AC{row}+40*I{row};0)",
            f"=MIN(4;MAX(1;1+MAX(0;AD{row}-195)*0.0005))", "='Activity Scenarios'.G2",
            f"=ROUND(ROUND(AF{row}*AE{row};0)*(1+U{row}/100);0)"]
        set_row(s, row - 1, values)
    style_range(s, "C2:I16", bg=pale_blue)
    style_range(s, "J2:AG16", bg=pale_green)
    s.getCellRangeByName("AE2:AE16").NumberFormat = 2
    for i in range(33): s.getColumns().getByIndex(i).Width = 3300
    width(s, "B", 5000)

    # Activity scenarios
    s = sheets.getByName("Activity Scenarios")
    headers = ["Activity", "Multiplier", "Minutes", "Distance km", "Calories", "Base damage", "Raw damage", "With player multiplier", "Notes"]
    set_row(s, 0, headers)
    style_range(s, "A1:I1", bg=navy, color=white, bold=True)
    activities = [
        ("Climbing", 1.3, 45, 0, 350), ("Running", 1.2, 40, 6, 400),
        ("Swimming", 1.1, 45, 1.5, 350), ("Gym", 1.0, 50, 0, 350),
        ("Cycling", 1.0, 60, 20, 500), ("Hiking", 1.0, 90, 8, 550),
        ("Yoga", 0.8, 40, 0, 150), ("Other", 1.0, 45, 0, 300),
    ]
    for idx, (name, mult, mins, km, cal) in enumerate(activities, 2):
        set_row(s, idx - 1, [name, mult, mins, km, cal,
            f"=E{idx}*0.5+C{idx}+D{idx}*3",
            f"=INT(F{idx}*B{idx})",
            f"=ROUND(G{idx}*Settings.B4*(1+Settings.B5/100);0)",
            "Editable representative workout"])
    style_range(s, "B2:E9", bg=pale_blue)
    style_range(s, "F2:H9", bg=pale_green)
    for col, val in zip("ABCDEFGHI", [4200, 3000, 3000, 3300, 3000, 3400, 3400, 5000, 8500]): width(s, col, val)

    # Combat V2 seeded bosses. HP/armor/counterattack match BossBalanceCalculator.
    bosses = [
        (1, "Forest of Endurance", 1, "Forest Warden", 10, 1200, 1824, 10, 7, 8, 8),
        (2, "Ocean of Balance", 8, "Tide Sovereign", 8, 1400, 1984, 15, 16, 8, 8),
        (3, "Mountains of Strength", 15, "Stone Titan", 8, 1600, 2120, 20, 24, 8, 8),
        (4, "Ashen Caldera", 25, "Molten King", 8, 1800, 2320, 25, 37, 8, 8),
        (5, "Frostspire Tundra", 32, "Hoarfrost Queen", 8, 2480, 3050, 30, 53, 10, 7),
        (6, "Sunscorch Dunes", 38, "Dune Pharaoh", 8, 2600, 3140, 35, 65, 10, 7),
        (7, "Shadewood Deep", 44, "Bramble Lord", 8, 2720, 3240, 40, 75, 10, 7),
        (8, "Moonlit Reef", 50, "Pearl Leviathan", 8, 2840, 3330, 45, 88, 10, 7),
        (9, "Thunderpeak Range", 56, "Storm Sovereign", 8, 2960, 3410, 50, 102, 10, 7),
        (10, "Emberfall Crater", 62, "Cinder Archon", 8, 3080, 3480, 55, 116, 10, 7),
        (11, "Glacier Abyss", 68, "Deepfrost Wyrm", 8, 3200, 4272, 60, 151, 12, 6),
        (12, "Mirage Wastes", 72, "Sand Kaiser", 8, 3280, 4296, 65, 163, 12, 6),
        (13, "Verdant Spine", 76, "Thornwarden", 8, 3360, 4320, 70, 177, 12, 6),
        (14, "Abyssal Trench", 80, "Maw of the Deep", 8, 3440, 4344, 75, 187, 12, 6),
        (15, "Apex Caldera", 85, "Worldflame", 8, 3540, 4380, 80, 203, 12, 6),
    ]
    s = sheets.getByName("Boss Balance")
    headers = [
        "Chapter", "Region", "Required level", "Boss", "Tier", "Type", "Boss HP", "Reward XP", "Timer days",
        "Raw dmg/workout", "Player dmg mult", "Boss bonus %", "Boss armor", "Armor K", "Boss mitigation",
        "Effective dmg/workout", "Target workouts", "Calculated workouts", "Workouts/day", "Days to win", "Timer check", "Reward XP/workout",
        "Player HP", "Player defense", "Boss counterattack", "Player mitigation", "Damage taken/turn", "Hits survived", "Target hits survived"
    ]
    set_row(s, 0, headers)
    style_range(s, "A1:AC1", bg=navy, color=white, bold=True)
    for r, (chapter, region, level, boss, tier, reward, hp, armor, counterattack, target_turns, target_hits) in enumerate(bosses, 2):
        values = [
            chapter, region, level, boss, tier, "World Boss", hp, reward, 0,
            f"='Player Builds'.AF{r}", f"='Player Builds'.AE{r}", f"='Player Builds'.U{r}", armor, "=Settings.B2", f"=M{r}/(M{r}+N{r})",
            f"=MAX(1;ROUND('Player Builds'.AG{r}*(1-O{r});0))", target_turns, f"=ROUNDUP(G{r}/P{r};0)", "=Settings.B6",
            f"=R{r}/S{r}", '="No timer"', f"=H{r}/R{r}",
            f"='Player Builds'.AC{r}", f"='Player Builds'.AB{r}", counterattack, f"=X{r}/(X{r}+N{r})",
            f"=MAX(1;ROUND(Y{r}*(1-Z{r});0))", f"=W{r}/AA{r}", target_hits
        ]
        set_row(s, r - 1, values)
    style_range(s, "A2:N16", bg=pale_blue)
    style_range(s, "O2:U16", bg=pale_green)
    style_range(s, "V2:Y16", bg=pale_orange)
    style_range(s, "Z2:AC16", bg=0xFFF3E5)
    s.getCellRangeByName("O2:O16").NumberFormat = 10
    s.getCellRangeByName("Z2:Z16").NumberFormat = 10
    s.getCellRangeByName("S2:S16").NumberFormat = 2
    s.getCellRangeByName("U2:U16").NumberFormat = 2
    s.getCellRangeByName("AA2:AC16").NumberFormat = 2
    widths = [2500, 5200, 3200, 4800, 2200, 3200, 3000, 3000, 2800, 4000, 3800, 3200, 3000, 2700, 3500, 4800, 4000, 3300, 3300, 3300, 4300, 3000, 3200, 3200, 3000, 3800, 3200, 3500, 3900]
    for i, w in enumerate(widths):
        s.getColumns().getByIndex(i).Width = w

    # Conditional formatting through simple formula-backed text colors is kept
    # intentionally portable across Excel and LibreOffice.
    for row in range(1, 16):
        s.getCellByPosition(19, row).CharWeight = 150.0

    staged_output = OUTPUT.with_name(f".{OUTPUT.stem}.generated{OUTPUT.suffix}")
    staged_output.unlink(missing_ok=True)
    doc.storeAsURL(
        uno.systemPathToFileUrl(str(staged_output)),
        (prop("FilterName", "Calc MS Excel 2007 XML"), prop("Overwrite", True)),
    )
    doc.close(True)
    staged_output.replace(OUTPUT)


if __name__ == "__main__":
    build_workbook()
    print(OUTPUT)
