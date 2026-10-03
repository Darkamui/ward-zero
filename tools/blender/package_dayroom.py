"""Validate both renders and optionally install their compressed backgrounds."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "production/art-review/g01_dayroom"
parser = argparse.ArgumentParser()
parser.add_argument("--install", action="store_true")
args = parser.parse_args()
manifest = json.loads((REVIEW / "render-manifest.json").read_text(encoding="utf-8"))
scene = ROOT / manifest["source_scene"]
if hashlib.sha256(scene.read_bytes()).hexdigest() != manifest["source_sha256"]:
    raise ValueError("Godot scene changed since rendering; review camera/layout alignment again")
if set(manifest["rendered_cameras"]) != {"cam_a", "cam_b"}:
    raise ValueError("Build both full-resolution cameras before packaging")
if set(manifest.get("rendered_states", [])) != {"locked", "released"}:
    raise ValueError("Build both chain states before packaging")
render_names = [camera + suffix for suffix in ("", "_released") for camera in ("cam_a", "cam_b")]
files = []
for camera in render_names:
    source = REVIEW / (camera + ".png")
    webp = REVIEW / (camera + ".webp")
    with Image.open(source) as image:
        image.load()
        if image.size != (1920, 1080) or image.mode != "RGB":
            raise ValueError(f"Unexpected render: {image.size}, {image.mode}")
        image.save(webp, "WEBP", quality=82, method=6)
    with Image.open(webp) as encoded:
        encoded.load()
        if encoded.size != (1920, 1080):
            raise ValueError("WebP dimensions changed")
    files.extend((source, webp))
if args.install:
    proxy = ROOT / "game/rooms/g01_dayroom/proxy.glb"
    if not proxy.is_file():
        raise ValueError("Matching visual proxy must exist before installation")
    for camera in render_names:
        shutil.copyfile(REVIEW / (camera + ".webp"), ROOT / "game/rooms/g01_dayroom/bg" / (camera + ".webp"))
runtime_file = REVIEW / "runtime/validation.json"
runtime = json.loads(runtime_file.read_text()) if runtime_file.exists() else {}
runtime_matches = bool(runtime.get("asset_sha256")) and all(
    hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == sha
    for path, sha in runtime.get("asset_sha256", {}).items()
)
report = dict(
    source_scene_hash_matches=True,
    png_size=[1920, 1080],
    webp_size=[1920, 1080],
    webp_quality=82,
    files={p.name: dict(bytes=p.stat().st_size, sha256=hashlib.sha256(p.read_bytes()).hexdigest())
           for p in files},
    runtime_integrated=args.install,
    runtime_occlusion_tested=runtime_matches and runtime.get("failures") == 0,
    runtime_report="runtime/validation.json" if runtime_matches else None,
)
(REVIEW / "validation.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
print(json.dumps(report, indent=2))
