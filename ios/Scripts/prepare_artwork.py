#!/usr/bin/env python3
"""Build the optimized iOS asset catalog from the supplied artwork PNGs.

Requires Pillow. Original assets are read-only; derived files are written to
ios/MusicasParaEstudar/Resources/Assets.xcassets and a source manifest to ios/.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from PIL import Image, ImageOps


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = REPOSITORY_ROOT / "imgs capas/componentes novos"
ASSET_ROOT = REPOSITORY_ROOT / "ios/MusicasParaEstudar/Resources/Assets.xcassets"
MANIFEST_PATH = REPOSITORY_ROOT / "ios/ARTWORK.json"
INK_MATTE = (23, 21, 34, 255)


def find_numbered(group: str, number: int) -> Path:
    folder = SOURCE_ROOT / group
    matches = [path for path in folder.glob("*.png") if re.search(rf"\({number}\)\.png$", path.name)]
    if len(matches) != 1:
        raise FileNotFoundError(f"Expected one source for {group} ({number}), found {len(matches)}")
    return matches[0]


def spec(
    asset: str,
    source: Path,
    group: str,
    title: str,
    purpose: str,
    *,
    crop: tuple[int, int, int, int] | None = None,
    max_side: int = 512,
    wide_max_side: int | None = None,
    composite_gradient: bool = False,
) -> dict[str, object]:
    return {
        "asset": asset,
        "source": source,
        "group": group,
        "title": title,
        "purpose": purpose,
        "crop": crop,
        "max_side": max_side,
        "wide_max_side": wide_max_side,
        "composite_gradient": composite_gradient,
    }


def artwork_specs() -> list[dict[str, object]]:
    covers = [
        spec(
            "FocusArtwork",
            find_numbered("capa thumbnails", 6),
            "collections",
            "Foco Profundo",
            "Home hero and focus category; ink bottle and score crop without embedded lettering.",
            crop=(0, 800, 640, 1200),
        ),
        spec(
            "PianoEveningArtwork",
            find_numbered("capa thumbnails", 7),
            "collections",
            "Piano e Chuva",
            "Piano para Dormir collection; keyboard detail crop without embedded lettering.",
            crop=(600, 650, 1200, 1250),
        ),
        spec(
            "ChopinMidnightArtwork",
            find_numbered("capa thumbnails", 8),
            "collections",
            "Noite com Chopin",
            "Explore collection; moonlit piano detail crop without embedded lettering.",
            crop=(600, 650, 1200, 1250),
        ),
        spec(
            "MozartMorningArtwork",
            find_numbered("capa thumbnails", 9),
            "collections",
            "Manhã com Mozart",
            "Explore collection; morning city detail crop without embedded lettering.",
            crop=(650, 50, 1250, 650),
        ),
        spec(
            "BeethovenPowerArtwork",
            find_numbered("capa thumbnails", 10),
            "collections",
            "Beethoven em Foco",
            "Explore collection; upper portrait crop without embedded lettering.",
            crop=(100, 20, 730, 650),
        ),
    ]

    composer_names = [
        "Bach", "Chopin", "Mozart", "Beethoven", "Vivaldi",
        "Debussy", "Satie", "Liszt", "Tchaikovsky", "Brahms",
    ]
    composers = [
        spec(
            f"{name}Portrait",
            find_numbered("compositores", number),
            "composers",
            name,
            "Explore and track artwork; portrait composited on a shared purple gradient with a native name and licensed-track count.",
            max_side=768,
            composite_gradient=True,
        )
        for number, name in enumerate(composer_names, start=1)
    ]

    instrument_names = [
        ("GrandPiano", "Piano de Cauda"),
        ("PianoKeys", "Teclas de Piano"),
        ("Violin", "Violino"),
        ("Cello", "Violoncelo"),
        ("Trumpet", "Trompete"),
        ("Flute", "Flauta"),
        ("RolledScore", "Partitura Enrolada"),
        ("OpenScore", "Partitura Aberta"),
        ("Headphones", "Fones de Ouvido"),
        ("ConductorBaton", "Batuta"),
    ]
    instruments = [
        spec(
            asset,
            find_numbered("inst musicas", number),
            "instruments",
            title,
            "Explore artwork gallery; instrument filters match catalog work terms, while score/listening materials link to related study categories.",
            max_side=384,
        )
        for number, (asset, title) in enumerate(instrument_names, start=1)
    ]

    study_names = [
        ("BooksStack", "Livros"),
        ("OpenStudyBook", "Livro Aberto"),
        ("Pencil", "Lápis"),
        ("CoffeeCup", "Café"),
        ("Laptop", "Notebook"),
        ("DeskLamp", "Luminária"),
        ("StudyPlant", "Planta"),
        ("Moon", "Lua"),
        ("Sun", "Sol"),
        ("Hourglass", "Ampulheta"),
    ]
    study_objects = [
        spec(
            asset,
            find_numbered("OBJETOS DE ESTUDO E PRODUTIVIDADE", number),
            "study_objects",
            title,
            "Focus ambience selector; native caption and selected state.",
            max_side=384,
        )
        for number, (asset, title) in enumerate(study_names, start=1)
    ]

    misc_sources = [
        ("TrebleClef", "Clé de Sol", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_29_57 (1).png"),
        ("MusicNotes", "Notas Musicais", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_29_57 (2).png"),
        ("MusicStaff", "Pauta Musical", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_29_58 (3).png"),
        ("StarOrnament", "Estrela Dourada", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_29_59 (4).png"),
        ("ConstellationOrnament", "Constelação", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_30_00 (5).png"),
        ("LeafBranch", "Ramo de Folhas", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_33 (1).png"),
        ("ClassicalColumn", "Coluna Clássica", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_34 (2).png"),
        ("MarbleColumn", "Coluna de Mármore", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_35 (3).png"),
        ("FlourishOrnament", "Filigrana", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_35 (4).png"),
        ("GoldRibbon", "Fita Dourada", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_37 (5).png"),
        ("BlackBow", "Laço Preto", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_37 (6).png"),
        ("Quill", "Pena", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_37 (7).png"),
        ("LyreEmblem", "Lira", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_38 (8).png"),
        ("LaurelBranch", "Loureiro", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_38 (9).png"),
        ("GoldDivider", "Divisor Dourado", "miscelanious/ChatGPT Image 24 de set. de 2026, 15_35_39 (10).png"),
    ]
    ornaments = [
        spec(
            asset,
            SOURCE_ROOT / source,
            "ornaments",
            title,
            "Decorative-only accent; hidden from VoiceOver and used sparingly in section and card composition.",
            max_side=512,
            wide_max_side=768,
        )
        for asset, title, source in misc_sources
    ]

    player_names = [
        ("PlayerPlay", "Reproduzir"),
        ("PlayerPause", "Pausar"),
        ("PlayerPrevious", "Faixa Anterior"),
        ("PlayerNext", "Próxima Faixa"),
        ("PlayerShuffle", "Aleatório"),
        ("PlayerRepeat", "Repetir Faixa"),
        ("PlayerVolume", "Silenciar"),
        ("PlayerFavorite", "Favoritar"),
        ("PlayerAdd", "Adicionar à Fila"),
        ("PlayerMore", "Mais Opções"),
    ]
    controls = [
        spec(
            asset,
            find_numbered("tocador player botoes", number),
            "player_controls",
            title,
            "Artwork inside a native SwiftUI control; tap target and VoiceOver label remain native.",
            max_side=256,
        )
        for number, (asset, title) in enumerate(player_names, start=1)
    ]

    return covers + composers + instruments + study_objects + ornaments + controls


def build_asset(item: dict[str, object], previous_filename: str | None = None) -> dict[str, object]:
    asset_name = str(item["asset"])
    source = Path(item["source"])
    output_format = "JPEG" if item["crop"] is not None or item["composite_gradient"] else "PNG"
    output_name = f"{re.sub(r'(?<!^)(?=[A-Z])', '_', asset_name).lower()}.{ 'jpg' if output_format == 'JPEG' else 'png' }"
    imageset = ASSET_ROOT / f"{asset_name}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    destination = imageset / output_name
    if previous_filename and previous_filename != output_name:
        stale_output = imageset / previous_filename
        if stale_output.is_file():
            stale_output.unlink()

    with Image.open(source) as original:
        source_size = list(original.size)
        image = original.convert("RGBA")
        if item["crop"] is not None:
            image = image.crop(item["crop"])
            matte = Image.new("RGBA", image.size, INK_MATTE)
            matte.alpha_composite(image)
            image = matte.convert("RGB")
            target = (720, 450) if image.width / image.height > 1.4 else (720, 720)
            image = image.resize(target, Image.Resampling.LANCZOS)
            image.save(destination, "JPEG", quality=82, optimize=True, progressive=True)
        elif item["composite_gradient"]:
            alpha = image.getchannel("A")
            bbox = alpha.getbbox()
            if bbox:
                image = image.crop(bbox)
            limit = int(item["max_side"])
            if max(image.size) > limit:
                scale = limit / max(image.size)
                image = image.resize(
                    (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
                    Image.Resampling.LANCZOS,
                )
            gradient = Image.linear_gradient("L").resize(image.size, Image.Resampling.BICUBIC)
            background = ImageOps.colorize(gradient, black=(28, 26, 46), white=(87, 71, 184)).convert("RGBA")
            background.alpha_composite(image)
            image = background.convert("RGB")
            image.save(destination, "JPEG", quality=86, optimize=True, progressive=True)
        else:
            alpha = image.getchannel("A")
            bbox = alpha.getbbox()
            if bbox:
                image = image.crop(bbox)
            limit = int(item["max_side"])
            if item["wide_max_side"] and max(image.size) / min(image.size) > 1.5:
                limit = int(item["wide_max_side"])
            if max(image.size) > limit:
                scale = limit / max(image.size)
                image = image.resize(
                    (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
                    Image.Resampling.LANCZOS,
                )
            image.save(destination, "PNG", optimize=True, compress_level=9)
        output_size = list(image.size)

    contents = {
        "images": [{"filename": output_name, "idiom": "universal", "scale": "1x"}],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")

    source_relative = source.relative_to(REPOSITORY_ROOT).as_posix()
    crop = item["crop"]
    if crop is not None:
        transform = f"crop={list(crop)}; composite=#171522; JPEG q82"
    elif item["composite_gradient"]:
        transform = f"alpha-crop; purple gradient composite; resize-max={item['max_side']}px; JPEG q86"
    else:
        transform = f"alpha-crop; resize-max={limit}px; optimized PNG"
    return {
        "asset": asset_name,
        "filename": output_name,
        "imageset": f"{asset_name}.imageset",
        "group": item["group"],
        "title": item["title"],
        "purpose": item["purpose"],
        "source": source_relative,
        "sourceSize": source_size,
        "outputSize": output_size,
        "outputBytes": destination.stat().st_size,
        "transform": transform,
        "rightsStatus": "provenance_not_recorded",
    }


def main() -> None:
    items = artwork_specs()
    if len(items) != 60:
        raise SystemExit(f"Expected 60 source artworks, found {len(items)}")
    names = [str(item["asset"]) for item in items]
    if len(set(names)) != len(names):
        raise SystemExit("Duplicate semantic artwork asset name")

    previous_outputs: dict[str, str] = {}
    if MANIFEST_PATH.is_file():
        previous_manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        previous_outputs = {entry["asset"]: entry["filename"] for entry in previous_manifest.get("assets", [])}
    manifest_entries = [build_asset(item, previous_outputs.get(str(item["asset"]))) for item in items]
    manifest = {
        "schemaVersion": 1,
        "originalsModified": False,
        "assetCount": len(manifest_entries),
        "licenseReview": "The supplied directory did not contain license/provenance evidence; verify before public distribution.",
        "assets": manifest_entries,
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    total_bytes = sum(int(entry["outputBytes"]) for entry in manifest_entries)
    print(f"Prepared {len(manifest_entries)} artwork assets: {total_bytes / 1024 / 1024:.2f} MiB")
    for group in sorted({str(entry['group']) for entry in manifest_entries}):
        entries = [entry for entry in manifest_entries if entry["group"] == group]
        size = sum(int(entry["outputBytes"]) for entry in entries)
        print(f"  {group}: {len(entries)} assets, {size / 1024 / 1024:.2f} MiB")


if __name__ == "__main__":
    main()
