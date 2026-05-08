#!/usr/bin/env python3
"""Extract PowerPoint slide text and speaker notes to Markdown."""

from __future__ import annotations

import argparse
import posixpath
import re
import sys
import zipfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable, NoReturn
from urllib.parse import unquote
from xml.etree import ElementTree as ET

REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
P_REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
A_NS = "http://schemas.openxmlformats.org/drawingml/2006/main"
P_NS = "http://schemas.openxmlformats.org/presentationml/2006/main"
R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

NS = {"a": A_NS, "p": P_NS, "r": R_NS, "rel": REL_NS}
NOTES_REL = f"{P_REL_NS}/notesSlide"
SLIDE_REL = f"{P_REL_NS}/slide"


@dataclass(frozen=True)
class SlideData:
    """Text extracted from a single slide and its speaker notes."""

    number: int
    slide_path: str
    slide_text: str
    notes_text: str


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments for the PPTX-to-Markdown converter."""

    parser = argparse.ArgumentParser(
        prog="pptx-notes-md",
        description="Extract slide content and speaker notes from PPTX files to Markdown.",
    )
    parser.add_argument("input", type=Path, help="PPTX file or folder to process recursively")
    parser.add_argument("-o", "--output", type=Path, help="Output Markdown path for single-file input")
    parser.add_argument("--stdout", action="store_true", help="Write Markdown to stdout for single-file input")
    parser.add_argument("--force", action="store_true", help="Overwrite existing output instead of timestamping")
    return parser.parse_args()


def die(message: str) -> NoReturn:
    """Print a fatal CLI error and exit with a non-zero status."""

    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def warn(message: str) -> None:
    """Print a non-fatal CLI warning."""

    print(f"WARN: {message}", file=sys.stderr)


def is_pptx(path: Path) -> bool:
    """Return whether a path points to an existing PowerPoint file."""

    return path.is_file() and path.suffix.lower() == ".pptx"


def iter_inputs(path: Path) -> list[Path]:
    """Return PPTX inputs from a file path or recursively from a directory."""

    if path.is_dir():
        return sorted(p for p in path.rglob("*.pptx") if p.is_file())
    if path.exists():
        return [path]
    die(f"input does not exist: {path}")


def part_rels_path(part_path: str) -> str:
    """Return the package relationship path for a PPTX part path."""

    directory, filename = posixpath.split(part_path)
    return posixpath.join(directory, "_rels", f"{filename}.rels")


def resolve_target(source_part: str, target: str) -> str:
    """Resolve a relationship target relative to its source package part."""

    target = unquote(target)
    if target.startswith("/"):
        return target.lstrip("/")
    base_dir = posixpath.dirname(source_part)
    return posixpath.normpath(posixpath.join(base_dir, target))


def read_xml(zf: zipfile.ZipFile, name: str) -> ET.Element | None:
    """Read and parse an XML member from a PPTX archive, if it exists."""

    try:
        return ET.fromstring(zf.read(name))
    except KeyError:
        return None
    except ET.ParseError as exc:
        raise ValueError(f"invalid XML in {name}: {exc}") from exc


def relationships(zf: zipfile.ZipFile, rels_path: str) -> dict[str, tuple[str, str]]:
    """Return relationship IDs mapped to (type, target) pairs."""

    root = read_xml(zf, rels_path)
    if root is None:
        return {}

    rels: dict[str, tuple[str, str]] = {}
    for rel in root.findall("rel:Relationship", NS):
        rel_id = rel.attrib.get("Id")
        rel_type = rel.attrib.get("Type")
        target = rel.attrib.get("Target")
        if rel_id and rel_type and target:
            rels[rel_id] = (rel_type, target)
    return rels


def slide_paths_in_order(zf: zipfile.ZipFile) -> list[str]:
    """Return slide part paths in the order defined by the presentation."""

    presentation = read_xml(zf, "ppt/presentation.xml")
    if presentation is None:
        raise ValueError("ppt/presentation.xml not found")

    pres_rels = relationships(zf, "ppt/_rels/presentation.xml.rels")
    paths: list[str] = []
    for slide_id in presentation.findall(".//p:sldIdLst/p:sldId", NS):
        rel_id = slide_id.attrib.get(f"{{{R_NS}}}id")
        if not rel_id or rel_id not in pres_rels:
            continue
        rel_type, target = pres_rels[rel_id]
        if rel_type == SLIDE_REL:
            paths.append(resolve_target("ppt/presentation.xml", target))
    return paths


def text_from_part(root: ET.Element | None) -> str:
    """Extract normalized DrawingML paragraph text from a slide or notes part."""

    if root is None:
        return ""

    blocks: list[str] = []
    for paragraph in root.findall(".//a:p", NS):
        runs: list[str] = []
        for node in paragraph.iter():
            if node.tag == f"{{{A_NS}}}t" and node.text:
                runs.append(node.text)
            elif node.tag == f"{{{A_NS}}}br":
                runs.append("\n")
        text = "".join(runs).strip()
        if text:
            blocks.append(text)
    return normalize_text("\n".join(blocks))


def normalize_text(text: str) -> str:
    """Collapse repeated whitespace while preserving paragraph breaks."""

    lines = [re.sub(r"[ \t]+", " ", line).strip() for line in text.splitlines()]
    compact: list[str] = []
    previous_blank = False
    for line in lines:
        if not line:
            if not previous_blank:
                compact.append("")
            previous_blank = True
        else:
            compact.append(line)
            previous_blank = False
    return "\n".join(compact).strip()


def notes_path_for_slide(zf: zipfile.ZipFile, slide_path: str) -> str | None:
    """Return the speaker-notes part path related to a slide, when present."""

    for rel_type, target in relationships(zf, part_rels_path(slide_path)).values():
        if rel_type == NOTES_REL:
            return resolve_target(slide_path, target)
    return None


def extract_deck(path: Path) -> list[SlideData]:
    """Extract slide content and speaker notes from a PPTX deck."""

    if not is_pptx(path):
        raise ValueError("input is not a .pptx file")

    try:
        with zipfile.ZipFile(path) as zf:
            slides: list[SlideData] = []
            for number, slide_path in enumerate(slide_paths_in_order(zf), start=1):
                slide_text = text_from_part(read_xml(zf, slide_path))
                notes_path = notes_path_for_slide(zf, slide_path)
                notes_text = text_from_part(read_xml(zf, notes_path)) if notes_path else ""
                slides.append(SlideData(number, slide_path, slide_text, notes_text))
            return slides
    except zipfile.BadZipFile as exc:
        raise ValueError("input is not a valid PPTX/ZIP file") from exc


def markdown_for_deck(path: Path, slides: Iterable[SlideData]) -> str:
    """Render extracted slide data as Markdown."""

    out = [f"# {path.name}", ""]
    for slide in slides:
        out.extend(
            [
                f"## Slide {slide.number}",
                "",
                "### Slide Content",
                "",
                slide.slide_text or "_No slide text found._",
                "",
                "### Speaker Notes",
                "",
                slide.notes_text or "_No speaker notes found._",
                "",
            ]
        )
    return "\n".join(out).rstrip() + "\n"


def timestamped_path(path: Path) -> Path:
    """Return a non-existing timestamped variant of an output path."""

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    candidate = path.with_name(f"{path.stem}_{stamp}{path.suffix}")
    counter = 1
    while candidate.exists():
        candidate = path.with_name(f"{path.stem}_{stamp}_{counter}{path.suffix}")
        counter += 1
    return candidate


def output_path_for(input_path: Path, explicit: Path | None, force: bool) -> Path:
    """Choose the Markdown output path for an input deck, timestamping if the path exists and force is not set."""

    output = explicit if explicit is not None else input_path.with_suffix(".md")
    if output.exists() and not force:
        return timestamped_path(output)
    return output


def write_markdown(input_path: Path, markdown: str, output: Path) -> Path:
    """Write Markdown to the given path, creating parent directories as needed."""

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(markdown, encoding="utf-8")
    return output


def convert_file(input_path: Path, output: Path | None, force: bool, stdout: bool) -> Path | None:
    """Convert one PPTX file to Markdown on disk or stdout."""

    slides = extract_deck(input_path)
    markdown = markdown_for_deck(input_path, slides)
    if stdout:
        print(markdown, end="")
        return None
    target = output_path_for(input_path, output, force)
    return write_markdown(input_path, markdown, target)


def main() -> int:
    """Run the command-line converter."""

    args = parse_args()
    inputs = iter_inputs(args.input)
    folder_mode = args.input.is_dir()

    if folder_mode and args.output:
        die("--output is only valid with a single PPTX file")
    if folder_mode and args.stdout:
        die("--stdout is only valid with a single PPTX file")
    if not folder_mode and len(inputs) == 1 and not is_pptx(inputs[0]):
        die(f"input is not a .pptx file: {inputs[0]}")

    converted = 0
    failed = 0
    skipped = 0

    if folder_mode:
        if not inputs:
            print(f"No PPTX files found under {args.input}")
            return 0
        for input_path in inputs:
            try:
                output_path = convert_file(input_path, None, args.force, False)
                converted += 1
                print(f"Converted: {input_path} -> {output_path}")
            except Exception as exc:  # noqa: BLE001 - CLI should keep processing folder entries.
                failed += 1
                warn(f"failed to convert {input_path}: {exc}")
        print(f"Summary: {converted} converted, {failed} failed, {skipped} skipped")
        return 1 if failed else 0

    try:
        output_path = convert_file(inputs[0], args.output, args.force, args.stdout)
        if output_path is not None:
            print(f"Wrote: {output_path}")
        return 0
    except Exception as exc:  # noqa: BLE001 - display concise CLI error.
        die(str(exc))


if __name__ == "__main__":
    raise SystemExit(main())
