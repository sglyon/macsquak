#!/usr/bin/env python3
import argparse, json, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--audio', required=True)
    ap.add_argument('--model', default='mlx-community/parakeet-tdt-0.6b-v3')
    args = ap.parse_args()

    try:
        from parakeet_mlx import from_pretrained
        model = from_pretrained(args.model)
        result = model.transcribe(args.audio)
        print(json.dumps({"text": result.text, "sentences": [s.text for s in getattr(result, 'sentences', [])]}))
    except Exception as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
