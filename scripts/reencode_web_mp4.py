#!/home/d501/anaconda3/envs/tmp/bin/python

from __future__ import annotations

import argparse
import os
import shutil
from pathlib import Path

import av


# /home/d501/data/lyh/ProAgent/project-page/scripts/reencode_web_mp4.py \
#   --dir /home/d501/data/lyh/ProAgent/results_featured_homepage_20260603_140617/featured_videos


def video_codec(path: Path) -> str:
    with av.open(str(path)) as container:
        for stream in container.streams:
            if stream.type == "video":
                return stream.codec_context.name
    raise RuntimeError(f"No video stream found in {path}")


def reencode_to_h264(input_path: Path, output_path: Path, crf: int = 23) -> None:
    with av.open(str(input_path)) as in_container:
        in_stream = next(stream for stream in in_container.streams if stream.type == "video")

        output_path.parent.mkdir(parents=True, exist_ok=True)
        with av.open(str(output_path), mode="w") as out_container:
            out_stream = out_container.add_stream("libx264", rate=in_stream.average_rate or in_stream.base_rate or 30)
            out_stream.width = in_stream.codec_context.width
            out_stream.height = in_stream.codec_context.height
            out_stream.pix_fmt = "yuv420p"
            out_stream.options = {
                "crf": str(crf),
                "preset": "medium",
                "movflags": "+faststart",
            }

            for frame in in_container.decode(in_stream):
                frame = frame.reformat(
                    width=out_stream.width,
                    height=out_stream.height,
                    format="yuv420p",
                )
                for packet in out_stream.encode(frame):
                    out_container.mux(packet)

            for packet in out_stream.encode():
                out_container.mux(packet)


def reencode_in_place(path: Path, crf: int) -> None:
    codec = video_codec(path)
    if codec == "h264":
        print(f"[skip] {path} is already H.264")
        return

    tmp_path = path.with_name(f".tmp.{path.name}")
    print(f"[reencode] {path} -> {tmp_path} (source codec: {codec})")
    reencode_to_h264(path, tmp_path, crf=crf)
    shutil.move(str(tmp_path), str(path))


def main() -> None:
    parser = argparse.ArgumentParser(description="Re-encode MP4 files to web-friendly H.264.")
    parser.add_argument("inputs", nargs="*", help="Input MP4 paths")
    parser.add_argument("--dir", dest="directory", help="Re-encode every .mp4 in a directory")
    parser.add_argument("--crf", type=int, default=23, help="x264 quality factor, lower is higher quality")
    args = parser.parse_args()

    targets: list[Path] = []
    if args.directory:
        targets.extend(sorted(Path(args.directory).glob("*.mp4")))
    targets.extend(Path(p) for p in args.inputs)

    if not targets:
        parser.error("Provide input files or --dir.")

    for path in targets:
        reencode_in_place(path, args.crf)


if __name__ == "__main__":
    main()
