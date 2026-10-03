"""Download the CC0 source maps used by build_dayroom.py (standard Python)."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
from urllib.request import urlopen, Request

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "art-src/shared/materials/peeling_painted_wall"
DEST.mkdir(parents=True, exist_ok=True)
(ROOT / "art-src/.gdignore").touch()


def fetch(kind):
    url = ("https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/"
           f"peeling_painted_wall/peeling_painted_wall_{kind}_2k.jpg")
    path = DEST / f"{kind}.jpg"
    if not path.exists():
        request = Request(url, headers={"User-Agent": "WardZeroArtBuild/1.0"})
        with urlopen(request, timeout=60) as response:
            path.write_bytes(response.read())
    data = path.read_bytes()
    if not data.startswith(b"\xff\xd8\xff"):
        raise ValueError(f"Not a JPEG: {path}")
    return dict(path=str(path.relative_to(ROOT)), url=url, bytes=len(data),
                sha256=hashlib.sha256(data).hexdigest())


if __name__ == "__main__":
    with ThreadPoolExecutor(max_workers=3) as pool:
        files = list(pool.map(fetch, ("diff", "disp", "rough")))
    manifest = dict(asset="Peeling Painted Wall", author="Dimitrios Savva",
                    source="https://polyhaven.com/a/peeling_painted_wall",
                    license="CC0-1.0", license_url="https://polyhaven.com/license", files=files)
    (DEST / "source.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))
