import sys

def hex_to_coe(input_file, output_file):
    with open(input_file, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    # Tạo nội dung COE
    coe_lines = ["memory_initialization_radix=16;", "memory_initialization_vector="]
    coe_lines.append(",\n".join(lines) + ";")  # các giá trị cách nhau bởi dấu ',' và kết thúc bằng ';'

    # Ghi file COE
    with open(output_file, "w") as f:
        f.write("\n".join(coe_lines))

    print(f"Converted {input_file} -> {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python mem_to_coe_converter.py <input_hex_file> <output_coe_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    hex_to_coe(input_file, output_file)
