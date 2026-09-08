#!/usr/bin/env python3
import sys

def convert_bytes_to_words(input_file, output_file, endian="little"):
    with open(input_file, "r") as f:
        lines = f.readlines()

    hex_bytes = []

    # Lọc dữ liệu: bỏ dòng @..., chỉ giữ token hex
    for line in lines:
        line = line.strip()
        if not line or line.startswith("@"):
            continue
        # thêm các token hex (cách nhau bởi space)
        hex_bytes.extend(line.split())

    # Padding nếu không chia hết cho 4
    if len(hex_bytes) % 4 != 0:
        print("⚠️ Warning: số byte không chia hết cho 4, padding thêm 0x00.")
        while len(hex_bytes) % 4 != 0:
            hex_bytes.append("00")

    words = []
    for i in range(0, len(hex_bytes), 4):
        b = hex_bytes[i:i+4]
        if endian == "little":
            # little-endian: byte thấp trước
            word = b[3] + b[2] + b[1] + b[0]
        else:
            # big-endian: byte cao trước
            word = b[0] + b[1] + b[2] + b[3]
        words.append(word)

    # Ghi ra file output
    with open(output_file, "w") as f:
        for w in words:
            f.write(w + "\n")

    print(f"✅ Converted {len(hex_bytes)} bytes → {len(words)} words (32-bit).")
    print(f"Output saved to {output_file}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python hex_convert.py input.hex output.hex [little|big]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    endian = sys.argv[3] if len(sys.argv) > 3 else "little"

    convert_bytes_to_words(input_file, output_file, endian)
