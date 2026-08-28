#!/usr/bin/env python3
"""Generate SCRIPT_INDEX.md from repository script files."""

from __future__ import annotations

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]

PREFIX_SECTIONS = [
    ("EXO", "Exchange Online", "Cloud_Scripts/Exchange_Management/"),
    ("SPO", "SharePoint Online / PnP Modern", "Cloud_Scripts/SharePoint/", "Cloud_Scripts/SharePoint/Migrations/"),
    ("TEA", "Microsoft Teams", "Cloud_Scripts/Teams/"),
    ("ENT", "Entra ID (Identity)", "Cloud_Scripts/Entra_ID/"),
    ("M365", "M365 Assessment", "Cloud_Scripts/M365_Assessment/"),
    ("INT", "Microsoft Intune / Endpoint", "Cloud_Scripts/Intune/Scripts/", "OnPremises_Scripts/Intune/", "OnPremises_Scripts/Intune/EndpointScripts/"),
    ("UTL", "Utilities", "Cloud_Scripts/Utilities/", "Cloud_Scripts/Utilities/Connection/", "Cloud_Scripts/Utilities/Common/", "Cloud_Scripts/Utilities/Templates/", "OnPremises_Scripts/Utilities/"),
    ("SEC", "Security (Information Protection)", "Cloud_Scripts/Security_and_Compliance/"),
    ("SCC", "Security & Compliance (Purview)", "Cloud_Scripts/Security_and_Compliance/"),
    ("OPR", "On-Premises", "OnPremises_Scripts/"),
    ("MIG", "Migration", "Cloud_Scripts/Migration/"),
]

SKIP_DIRS = {"Backups", "SRIntuneConfigManagement", "Win32_App_Packages", "CSS-Exchange", ".git", "scripts"}

SCRIPT_RE = re.compile(r"^(M365|[A-Z]{2,3})-(\d{3})_(.+)\.ps1$")


def extract_description(path: Path) -> str:
    text = path.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"\.SYNOPSIS\s*\n\s*(.+?)(?:\n\n|\n\.)", text, re.DOTALL)
    if m:
        line = m.group(1).strip().split("\n")[0].strip()
        # Remove script ID prefix if duplicated
        line = re.sub(r"^(M365|[A-Z]{2,3})-\d{3}\s*\|\s*", "", line)
        return line.rstrip(".")
    return path.stem.replace("_", " ")


def find_scripts() -> dict[str, list[tuple[int, str, str, str]]]:
    by_prefix: dict[str, list[tuple[int, str, str, str]]] = {}
    for path in REPO.rglob("*.ps1"):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        m = SCRIPT_RE.match(path.name)
        if not m:
            continue
        prefix, num, _ = m.groups()
        rel = path.relative_to(REPO).as_posix()
        desc = extract_description(path)
        by_prefix.setdefault(prefix, []).append((int(num), path.name, rel, desc))
    for prefix in by_prefix:
        by_prefix[prefix].sort(key=lambda x: x[0])
    return by_prefix


def section_icon(prefix: str) -> str:
    return {
        "EXO": "📧", "SPO": "📦", "TEA": "💬", "ENT": "🔐", "M365": "📊",
        "INT": "🖥️", "UTL": "🔧", "SEC": "🛡️", "SCC": "🔒", "OPR": "🏢", "MIG": "🗂️",
    }.get(prefix, "📄")


def build_index(scripts: dict[str, list]) -> str:
    lines = [
        "# 📘 Microsoft Workspace – Script Index",
        "> **All scripts are in English, organized by technology/product, and individually numbered.**",
        "> Last updated: August 2026 | Maintainer: Josep Canas – M365 Solutions Architect",
        "> O365scripts upstream integration: see [O365SCRIPTS_MAP.md](O365SCRIPTS_MAP.md)",
        "",
        "---",
        "",
        "## Naming Convention",
        "",
        "```",
        "<PREFIX>-<NNN>_<ShortDescription>.ps1",
        "```",
        "",
        "| Prefix | Technology / Product |",
        "|--------|----------------------|",
        "| `EXO`  | Exchange Online / Defender for Office 365 |",
        "| `SPO`  | SharePoint Online / PnP Modern |",
        "| `TEA`  | Microsoft Teams |",
        "| `ENT`  | Entra ID / Azure AD Connect / Identity |",
        "| `M365` | M365 Assessment (cross-service / Graph) |",
        "| `INT`  | Microsoft Intune / Autopilot / Endpoint Manager |",
        "| `UTL`  | Utilities (connectivity, modules, helpers) |",
        "| `SEC`  | Azure Information Protection |",
        "| `SCC`  | Security & Compliance / Purview |",
        "| `OPR`  | On-Premises infrastructure |",
        "| `MIG`  | Migration (BitTitan, cross-tenant) |",
        "",
        "---",
        "",
    ]

    section_order = ["EXO", "SPO", "TEA", "ENT", "M365", "INT", "UTL", "SEC", "SCC", "OPR", "MIG"]
    section_titles = {p: t for p, t, *_ in PREFIX_SECTIONS}

    for prefix in section_order:
        if prefix not in scripts:
            continue
        title = section_titles.get(prefix, prefix)
        icon = section_icon(prefix)
        paths = next((list(s[2:]) for s in PREFIX_SECTIONS if s[0] == prefix), [])
        path_note = "> Path: " + ", ".join(f"`{p}`" for p in paths)
        lines.extend([
            f"## {icon} {title} ({prefix})",
            "",
            path_note,
            "",
            "| # | File | Description |",
            "|---|------|-------------|",
        ])
        for num, name, rel, desc in scripts[prefix]:
            script_id = f"{prefix}-{num:03d}"
            lines.append(f"| {script_id} | `{rel}` | {desc} |")
        lines.extend(["", "---", ""])

    total = sum(len(v) for v in scripts.values())
    lines.extend([
        f"## Summary",
        "",
        f"**Total indexed scripts:** {total}",
        "",
        "## Workflow Map: Recommended Execution Order",
        "",
        "```",
        "─── Assessment Phase ────────────────────────────────────────",
        "  M365-001 → M365-019 | M365-007 (Entra ID) | ENT-002",
        "  TEA-001 → TEA-004, TEA-018, TEA-023 | SPO-001 → SPO-010",
        "  OPR-001 → OPR-003",
        "",
        "─── Hardening / Onboarding Phase ────────────────────────────",
        "  EXO-005 → EXO-001 → EXO-004 → EXO-020",
        "",
        "─── Migration Phase ─────────────────────────────────────────",
        "  SPO-002 or SPO-003 → SPO-004 → SPO-007 → SPO-005 → SPO-006",
        "",
        "─── Teams Voice Phase ───────────────────────────────────────",
        "  TEA-011 → TEA-012 → TEA-020 → TEA-022 → TEA-023",
        "",
        "─── Intune / Endpoint Phase ─────────────────────────────────",
        "  INT-001 → INT-008 → INT-009 → INT-019",
        "",
        "─── Utilities (use as needed) ────────────────────────────────",
        "  UTL-001 → UTL-005 → UTL-009 → UTL-035",
        "```",
        "",
    ])
    return "\n".join(lines)


if __name__ == "__main__":
    scripts = find_scripts()
    index = build_index(scripts)
    out = REPO / "SCRIPT_INDEX.md"
    out.write_text(index, encoding="utf-8")
    total = sum(len(v) for v in scripts.values())
    print(f"SCRIPT_INDEX.md written with {total} scripts across {len(scripts)} prefixes.")
