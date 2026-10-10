"""Atlas the embedded Mixamo body/clothing maps; preserve separate masked hair."""

from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / "art-src/characters/mathieu/mixamo"


def main():
    for kind in ("Diffuse", "Normal", "Glossiness"):
        atlas = Image.new("RGB", (2048, 1024))
        for index, tile in enumerate(("1001", "1002")):
            image = Image.open(WORK / "embedded" / f"Ch08_{tile}_{kind}.png").convert("RGB")
            image = image.resize((1008, 1008), Image.Resampling.LANCZOS)
            if kind == "Glossiness":
                image = ImageOps.invert(image)
            atlas.paste(image, (index * 1024 + 8, 8))
            atlas.paste(image.crop((0, 0, 1008, 1)).resize((1008, 8)), (index * 1024 + 8, 0))
            atlas.paste(image.crop((0, 1007, 1008, 1008)).resize((1008, 8)), (index * 1024 + 8, 1016))
            atlas.paste(image.crop((0, 0, 1, 1008)).resize((8, 1008)), (index * 1024, 8))
            atlas.paste(image.crop((1007, 0, 1008, 1008)).resize((8, 1008)), (index * 1024 + 1016, 8))
        atlas.save(WORK / f"body_{kind}.png")
    hair = Image.open(WORK / "embedded/Ch08_1003_Diffuse.png").convert("RGBA")
    hair.resize((1024, 1024), Image.Resampling.LANCZOS).save(WORK / "hair.png")


if __name__ == "__main__":
    main()
