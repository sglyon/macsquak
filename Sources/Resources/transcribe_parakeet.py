#!/usr/bin/env python3
import argparse
import json
import os
import sys
import time


def emit(ok: bool, text: str | None = None, model: str | None = None, elapsed: float | None = None, error: str | None = None):
    payload = {
        "ok": ok,
        "text": text,
        "model": model,
        "elapsed_seconds": elapsed,
        "error": error,
    }
    print(json.dumps(payload, ensure_ascii=False))


def ensure_ffmpeg_available() -> str:
    """Ensure ffmpeg is available and return executable path.

    We vendor ffmpeg via imageio-ffmpeg inside the app's uv-managed venv.
    """
    try:
        import imageio_ffmpeg
        ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
        ffmpeg_dir = os.path.dirname(ffmpeg_exe)
        os.environ["PATH"] = ffmpeg_dir + os.pathsep + os.environ.get("PATH", "")
        os.environ.setdefault("FFMPEG_BINARY", ffmpeg_exe)
        return ffmpeg_exe
    except Exception as e:
        raise RuntimeError(f"Failed to provision ffmpeg via imageio-ffmpeg: {e}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--audio', required=True)
    ap.add_argument('--model', default='mlx-community/parakeet-tdt-0.6b-v3')
    args = ap.parse_args()

    t0 = time.time()

    try:
        ffmpeg_exe = ensure_ffmpeg_available()
    except Exception as e:
        emit(False, model=args.model, elapsed=time.time() - t0, error=str(e))
        return 1

    try:
        from parakeet_mlx import from_pretrained
    except Exception as e:
        emit(False, model=args.model, elapsed=time.time() - t0, error=f"Failed to import parakeet_mlx: {e}")
        return 1

    try:
        model = from_pretrained(args.model)
        result = model.transcribe(args.audio)
        text = getattr(result, 'text', None)
        if not text:
            emit(False, model=args.model, elapsed=time.time() - t0, error="Model returned empty transcript")
            return 2
        emit(True, text=text, model=args.model, elapsed=time.time() - t0)
        return 0
    except Exception as e:
        emit(False, model=args.model, elapsed=time.time() - t0, error=f"ffmpeg={ffmpeg_exe}; {e}")
        return 3


if __name__ == '__main__':
    raise SystemExit(main())
