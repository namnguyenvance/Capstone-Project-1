# TinyMobileNet trên RISC-V SoC — Walkthrough Đồ Án Chi Tiết

## Mục Lục

1. [Tổng Quan Đồ Án](#1-tổng-quan-đồ-án)
2. [Kiến Trúc Hệ Thống (SoC)](#2-kiến-trúc-hệ-thống-soc)
3. [Mô Hình Neural Network: TinyMobileNet](#3-mô-hình-neural-network-tinymobilenet)
4. [Pipeline Huấn Luyện & Lượng Tử Hóa (Quantization)](#4-pipeline-huấn-luyện--lượng-tử-hóa-quantization)
5. [Các Hardware Accelerator](#5-các-hardware-accelerator)
6. [Firmware: Boot & Inference Pipeline](#6-firmware-boot--inference-pipeline)
7. [Phần Mềm Deep Learning Operations](#7-phần-mềm-deep-learning-operations)
8. [Memory Map & Bus Protocol](#8-memory-map--bus-protocol)
9. [Kết Quả Benchmark](#9-kết-quả-benchmark)
10. [Cấu Trúc File Dự Án](#10-cấu-trúc-file-dự-án)

---

## 1. Tổng Quan Đồ Án

### 1.1 Mục tiêu

Triển khai mô hình nhận diện ảnh **TinyMobileNet** (phân loại chữ số viết tay MNIST, 10 lớp) trên một hệ thống SoC vi xử lý **RISC-V 32-bit** (PicoRV32) có tích hợp **5 hardware accelerator** chuyên dụng, sử dụng lượng tử hóa **int8** để chạy inference hoàn toàn trên phần cứng nhúng.

### 1.2 Điểm nổi bật

| Đặc điểm | Chi tiết |
|-----------|----------|
| **CPU** | PicoRV32 (RV32IM — base integer + multiply, không hardware divide) |
| **RAM** | 256 KB SRAM on-chip |
| **Mô hình AI** | TinyMobileNet — lấy cảm hứng từ MobileNetV2, thu nhỏ cho MCU |
| **Lượng tử hóa** | Full int8 (TensorFlow Lite post-training quantization) |
| **Accelerator** | 5 module phần cứng: multiply, 3×3 conv, quantization, DW conv, PW conv |
| **Dataset** | MNIST 28×28 grayscale (10 classes: chữ số 0–9) |
| **Simulation** | Icarus Verilog (iverilog + vvp), testbench với UART output |
| **Toolchain** | riscv32-unknown-elf-gcc, -march=rv32im |

### 1.3 Sơ đồ tổng quan

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TinyMobileNet SoC                            │
│                                                                     │
│  ┌──────────────┐    ┌────────────────────────────────────────────┐ │
│  │  PicoRV32    │    │          Memory-Mapped Peripherals         │ │
│  │  CPU Core    │◄──►│                                            │ │
│  │  (RV32IM)    │    │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐ │ │
│  │              │    │  │ UART │ │ LEDs │ │ RAM  │ │Multiplier│ │ │
│  │  - Barrel    │    │  └──────┘ └──────┘ │256KB │ │ Accel    │ │ │
│  │    Shifter   │    │                    └──────┘ └──────────┘ │ │
│  │  - HW MUL    │    │  ┌──────────┐ ┌──────────┐ ┌──────────┐ │ │
│  │  - Counters  │    │  │ Conv 3×3 │ │ Quant    │ │ DW Conv  │ │ │
│  │              │    │  │ Accel    │ │ Accel    │ │ 3×3 Accel│ │ │
│  └──────────────┘    │  └──────────┘ └──────────┘ └──────────┘ │ │
│                      │  ┌──────────┐                            │ │
│                      │  │ PW Conv  │                            │ │
│                      │  │ Dot Prod │                            │ │
│                      │  │ Accel    │                            │ │
│                      │  └──────────┘                            │ │
│                      └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Kiến Trúc Hệ Thống (SoC)

### 2.1 CPU Core — PicoRV32

PicoRV32 là một CPU RISC-V 32-bit mã nguồn mở, siêu nhẹ, được thiết kế cho FPGA. Cấu hình sử dụng trong đồ án:

```verilog
picorv32 #(
    .PROGADDR_RESET(32'h00000000),  // Boot từ địa chỉ 0
    .STACKADDR(32'h00040000),       // Stack ở đỉnh RAM (256KB)
    .BARREL_SHIFTER(1),             // Shift nhanh (1 cycle)
    .COMPRESSED_ISA(0),             // Không dùng RV32C
    .ENABLE_COUNTERS(1),            // Cho phép đọc cycle counter (rdcycle)
    .ENABLE_MUL(1),                 // Hỗ trợ lệnh MUL/MULH (M extension)
    .ENABLE_DIV(0),                 // Không có hardware divide
    .ENABLE_IRQ(0)                  // Không cần interrupt
) cpu ( ... );
```

**Giao tiếp bus đơn giản:**
- `mem_valid`: CPU muốn đọc/ghi memory
- `mem_ready`: Peripheral phản hồi hoàn thành
- `mem_addr[31:0]`: Địa chỉ 32-bit
- `mem_wdata[31:0]` + `mem_wstrb[3:0]`: Dữ liệu ghi + byte strobe
- `mem_rdata[31:0]`: Dữ liệu đọc về

### 2.2 Memory — 256 KB SRAM

```verilog
localparam RAM_SIZE = 65536;         // 65536 words × 4 bytes = 256 KB
reg [31:0] ram [0:RAM_SIZE-1];
```

Chứa toàn bộ: firmware code, model weights/biases (~6KB), test images, stack, và computation buffers.

### 2.3 Peripherals

| Peripheral | Địa chỉ | Chức năng |
|-----------|---------|-----------|
| **SRAM** | `0x00000000 – 0x0003FFFF` | 256 KB RAM (code + data) |
| **UART Data** | `0x02000008` | Gửi/nhận ký tự qua serial |
| **UART Divider** | `0x02000004` | Cấu hình baud rate |
| **Multiplier** | `0x02000010 – 0x0200001F` | Phép nhân 32×32 |
| **Conv 3×3 Accel** | `0x02000100 – 0x020001FF` | Tích chập 2D 3×3 |
| **Quant Accel** | `0x02000200 – 0x020002FF` | SaturatingRoundingDoubling... |
| **DW Conv Accel** | `0x02000300 – 0x020003FF` | Depthwise Conv 3×3 |
| **PW Conv Accel** | `0x02000400 – 0x020007FF` | Pointwise Conv (dot product) |
| **LEDs** | `0x03000000` | 8 LED trạng thái |

### 2.4 Bus Arbitration

SoC dùng cơ chế priority mux đơn giản — mỗi peripheral có tín hiệu `_sel` (address decode) và `_ready` (response). Response logic:

```verilog
assign mem_ready = ram_ready || led_ready || uart_div_sel || 
    (uart_dat_sel && !reg_dat_wait) || accel_ready || 
    conv_accel_ready || quant_accel_ready || 
    dw_conv_accel_ready || pw_conv_accel_ready;

assign mem_rdata = ram_ready           ? ram_rdata :
                   uart_div_sel        ? uart_div_do :
                   uart_dat_sel        ? uart_dat_do :
                   accel_ready         ? accel_rdata :
                   conv_accel_ready    ? conv_accel_rdata :
                   quant_accel_ready   ? quant_accel_rdata :
                   dw_conv_accel_ready ? dw_conv_accel_rdata :
                   pw_conv_accel_ready ? pw_conv_accel_rdata :
                   32'h00000000;
```

> Mỗi peripheral mất **2 clock cycles** cho một transaction: 1 cycle để nhận request, 1 cycle để assert `ready`.

---

## 3. Mô Hình Neural Network: TinyMobileNet

### 3.1 Thiết kế mạng

TinyMobileNet được lấy cảm hứng từ **MobileNetV2** của Google, thu nhỏ lại cho vi xử lý nhúng:

```
Input 28×28×1 (ảnh MNIST grayscale)
    │
    ▼
Conv2D 3×3, 16 filters, stride 1, same padding, ReLU6     → 28×28×16
    │
    ▼
╔══════════════════════════════════════════════════════════╗
║ DW Block 1:                                              ║
║   DepthwiseConv2D 3×3, stride 1, same padding, ReLU6    ║ → 28×28×16
║   Conv2D 1×1 (Pointwise), 32 filters, ReLU6             ║ → 28×28×32
╚══════════════════════════════════════════════════════════╝
    │
    ▼
╔══════════════════════════════════════════════════════════╗
║ DW Block 2:                                              ║
║   DepthwiseConv2D 3×3, stride 2, same padding, ReLU6    ║ → 14×14×32
║   Conv2D 1×1 (Pointwise), 48 filters, ReLU6             ║ → 14×14×48
╚══════════════════════════════════════════════════════════╝
    │
    ▼
╔══════════════════════════════════════════════════════════╗
║ DW Block 3:                                              ║
║   DepthwiseConv2D 3×3, stride 2, same padding, ReLU6    ║ → 7×7×48
║   Conv2D 1×1 (Pointwise), 64 filters, ReLU6             ║ → 7×7×64
╚══════════════════════════════════════════════════════════╝
    │
    ▼
GlobalAveragePooling2D                                      → 64
    │
    ▼
Dense (Fully Connected), 10 units, softmax                  → 10
    │
    ▼
Output: 10 scores (các chữ số 0–9)
```

### 3.2 Depthwise Separable Convolution — Core concept

Đây là kỹ thuật then chốt của MobileNet. Thay vì dùng Conv2D tiêu chuẩn, mỗi block convolution được tách thành 2 bước:

**Standard Conv2D** (tốn tài nguyên):
```
Output[oc] = Σ_ic Σ_ky Σ_kx  Input[ic][y+ky][x+kx] × Kernel[oc][ic][ky][kx]
             ↑ lặp qua TẤT CẢ input channels
```
Complexity: `O(K² × Cin × Cout × H × W)`

**Depthwise Separable** (tiết kiệm):
```
Bước 1 — Depthwise: Mỗi input channel conv riêng biệt
    DW_Out[ic] = Σ_ky Σ_kx  Input[ic][y+ky][x+kx] × DW_Kernel[ic][ky][kx]
                 ↑ chỉ 1 channel, KHÔNG cross-channel

Bước 2 — Pointwise (1×1 conv): Trộn channels
    Out[oc] = Σ_ic  DW_Out[ic][y][x] × PW_Kernel[oc][ic]
              ↑ dot product across channels, KHÔNG có spatial kernel
```
Complexity: `O(K² × Cin × H × W) + O(Cin × Cout × H × W)`

> Với K=3, Cout=32: Standard = 9×Cin×32 = 288×Cin ops/pixel. Separable = 9×Cin + Cin×32 = 41×Cin ops/pixel → **~7× ít computation hơn!**

### 3.3 Global Average Pooling vs Flatten

Thay vì `Flatten(7×7×64) → Dense(3136→10)` = **31,360 tham số**, TinyMobileNet dùng:

`GlobalAveragePooling(7×7×64) → Dense(64→10)` = **640 tham số** — giảm **~49×** số tham số FC layer!

```
GAP: Mỗi channel → lấy trung bình tất cả spatial positions
     7×7×64 → 64 giá trị (mỗi giá trị = average của 49 pixels cùng channel)
```

### 3.4 ReLU6 Activation

Thay vì ReLU thông thường (`max(0, x)`), MobileNet dùng ReLU6 (`min(max(0, x), 6)`). Lý do: giới hạn giá trị đầu ra trong khoảng [0, 6] giúp lượng tử hóa int8 chính xác hơn vì dynamic range hẹp hơn.

### 3.5 Model Parameters (Quantized int8)

| Layer | Kernel | Weights (bytes) | Biases (bytes) | Total |
|-------|--------|----------------|----------------|-------|
| Conv0 3×3 [1→16] | 3×3×1×16 | 144 | 64 | 208 |
| DW1 3×3 [16ch] | 3×3×16 | 144 | 64 | 208 |
| PW1 1×1 [16→32] | 1×1×16×32 | 512 | 128 | 640 |
| DW2 3×3 [32ch] | 3×3×32 | 288 | 128 | 416 |
| PW2 1×1 [32→48] | 1×1×32×48 | 1,536 | 192 | 1,728 |
| DW3 3×3 [48ch] | 3×3×48 | 432 | 192 | 624 |
| PW3 1×1 [48→64] | 1×1×48×64 | 3,072 | 256 | 3,328 |
| Dense [64→10] | 64×10 | 640 | 40 | 680 |
| **Tổng** | | **6,768** | **1,064** | **~7.8 KB** |

---

## 4. Pipeline Huấn Luyện & Lượng Tử Hóa (Quantization)

### 4.1 Quy trình 4 bước

```
 train_model.py          generate_model_data.py       extract_mnist_test.py
 ┌────────────┐          ┌──────────────────┐         ┌──────────────────┐
 │ 1. Train   │          │ 3. Extract       │         │ 4. Extract       │
 │    float   │──────►   │    weights,      │         │    test images   │
 │    model   │   ┌──►   │    biases,       │         │    & labels      │
 │            │   │      │    quant params  │         │    to C arrays   │
 │ 2. Quantize│───┘      │    to C arrays   │         │                  │
 │    to int8 │          │                  │         │                  │
 └────────────┘          └──────────────────┘         └──────────────────┘
       │                        │                            │
       ▼                        ▼                            ▼
 .keras + .tflite    tinymobilenet_model_data.c/h     mnist_test_images.h
```

### 4.2 Bước 1–2: Training + Quantization (`train_model.py`)

```python
# Train float model (10 epochs, Adam optimizer)
model = build_tiny_mobilenet()
model.fit(x_train, y_train, epochs=10, batch_size=64)

# Post-Training Quantization (PTQ) → full int8
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset  # 200 calibration samples
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int8
converter.inference_output_type = tf.int8
tflite_model = converter.convert()
```

**Kết quả quantization:**
- Float accuracy: ~98%+
- Int8 accuracy: ~97%+ (chỉ giảm ~1%)
- Model size: ~21 KB (`.tflite`)

### 4.3 Bước 3: Extract Model Data (`generate_model_data.py`)

Script này đọc file `.tflite` và xuất ra C source code chứa:

**Cho mỗi layer:**
- `input_offset` = `−zero_point` (để chuyển int8 → int32 khi tính toán)
- `output_offset` = `zero_point` (để chuyển kết quả int32 → int8)
- `output_multiplier[]` + `output_shift[]` = per-channel quantization scaling
- `kernel_data[]` = int8 weights (đã transpose phù hợp memory layout)
- `bias_data[]` = int32 biases (pre-scaled)

**Cách tính quantized multiplier:**
```python
def compute_quantized_multiplier_and_shift(real_multiplier):
    # real_multiplier = (input_scale × weight_scale) / output_scale
    # Biểu diễn dạng: real_mult ≈ quantized_mult × 2^(-shift)
    # Trong đó quantized_mult là Q0.31 fixed-point
    significand = real_multiplier
    while significand < 0.5:
        significand *= 2.0; shift -= 1
    while significand >= 1.0:
        significand /= 2.0; shift += 1
    quantized_multiplier = round(significand × 2^31)
    right_shift = -shift
    return quantized_multiplier, right_shift
```

### 4.4 Lượng tử hóa — Nguyên lý chi tiết

Mỗi tensor int8 biểu diễn một giá trị float bằng:

```
float_value = (int8_value − zero_point) × scale
```

Khi thực hiện Conv2D lượng tử hóa:

```
1. Tính accumulator (int32):
   acc = bias + Σ (weight_int8 × (input_int8 + input_offset))
   
2. Scale accumulator về output range:
   acc = MultiplyByQuantizedMultiplier(acc, multiplier, shift)
   
3. Thêm output zero-point và clamp:
   result = clamp(acc + output_offset, -128, 127)
   
4. Cast về int8:
   output = (int8_t)result
```

> `input_offset = −input_zero_point` vì ta cần `(input − zero_point)` = `(input + input_offset)`.

---

## 5. Các Hardware Accelerator

### 5.1 Tổng quan 5 Accelerator

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Hardware Accelerator Family                           │
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │  my_accel    │  │my_conv_accel │  │my_quant_accel│                  │
│  │  (Multiplier)│  │  (Conv 3×3)  │  │(Quantization)│                  │
│  │              │  │              │  │              │                  │
│  │  A × B → P  │  │ 5×5 img tile │  │ x × mult    │                  │
│  │  (32×32 bit) │  │ 3×3 kernel   │  │ >> shift    │                  │
│  │              │  │ → 3×3 output │  │ + rounding  │                  │
│  │  Addr: 0x10  │  │  Addr: 0x100 │  │  Addr: 0x200│                  │
│  └──────────────┘  └──────────────┘  └──────────────┘                  │
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐                            │
│  │ my_dw_conv_accel  │  │ my_pw_conv_accel  │                          │
│  │ (DW Conv 3×3)     │  │ (PW Conv Dot Prod)│                          │
│  │                   │  │                   │                          │
│  │ Same HW as conv   │  │ 64 input + 64 wt  │                          │
│  │ accel, nhưng khác │  │ registers         │                          │
│  │ ở cách sử dụng    │  │ → parallel MAC    │                          │
│  │ từ software       │  │ → 1-cycle result  │                          │
│  │                   │  │                   │                          │
│  │  Addr: 0x300      │  │  Addr: 0x400      │                          │
│  └──────────────────┘  └──────────────────┘                            │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Accelerator #1: Simple Multiplier (`my_accel`)

**Mục đích:** Phép nhân 32×32 → 32 bit (combinational, 0-cycle latency)

| Register | Offset | R/W | Mô tả |
|----------|--------|-----|-------|
| REG_A | 0x10 | R/W | Operand A |
| REG_B | 0x14 | R/W | Operand B |
| PRODUCT | 0x18 | R | A × B (combinational) |

```verilog
wire [31:0] product = reg_a * reg_b;  // Phần cứng nhân tức thời
```

### 5.3 Accelerator #2: 2D Convolution 3×3 (`my_conv_accel`)

**Mục đích:** Tính tích chập 2D với kernel 3×3 trên tile input 5×5, xuất 3×3 = 9 kết quả song song.

**Register Map (base 0x02000100, 256 bytes):**

| Register | Index | Mô tả |
|----------|-------|-------|
| `IMG[0..24]` | 0–24 | Input tile 5×5 (25 giá trị int32) |
| `KER[0..8]` | 28–36 | Kernel 3×3 (9 giá trị int32) |
| `OUT[0..8]` | 40–48 | Output tile 3×3 (9 kết quả int32) |
| `CTRL` | 60 | Ghi `1` → trigger tính toán |

**Cách tính toán (registered, 1-cycle latency):**
```
Khi ghi CTRL = 1:
  OUT[0] = IMG[0]×KER[0] + IMG[1]×KER[1] + IMG[2]×KER[2] +
           IMG[5]×KER[3] + IMG[6]×KER[4] + IMG[7]×KER[5] +
           IMG[10]×KER[6] + IMG[11]×KER[7] + IMG[12]×KER[8]
  
  OUT[1] = IMG[1]×KER[0] + IMG[2]×KER[1] + IMG[3]×KER[2] + ...
  ... (9 tích chập song song, sliding window trên 5×5 tile)
```

**9 multiplier arrays** tính song song → 81 phép nhân trong 1 clock cycle!

**Software flow cho Conv0 3×3 [1→16]:**
```c
for (out_channel = 0..15) {
    for (tile_y, tile_x — tiling 28×28 thành 3×3 tiles) {
        acc[0..8] = bias[out_channel];  // khởi tạo
        for (in_channel = 0..Cin-1) {
            // 1. Load 3×3 kernel cho (out_channel, in_channel) vào KER[]
            // 2. Load 5×5 input tile (với input_offset) vào IMG[]
            // 3. Trigger: CONV_ACCEL_CTRL = 1
            // 4. Đọc 9 kết quả: acc[i] += CONV_ACCEL_OUT[i]
        }
        // Quantize 9 outputs: MultiplyByQuantizedMultiplier → int8
    }
}
```

### 5.4 Accelerator #3: Quantization (`my_quant_accel`)

**Mục đích:** Tính `SaturatingRoundingDoublingHighMul` + `RoundingDivideByPOT` bằng phần cứng. Đây là phép toán quantization scaling theo chuẩn TFLite.

| Register | Offset | Mô tả |
|----------|--------|-------|
| RAW | 0x00 | Raw accumulator value (int32) |
| MUL | 0x04 | Quantized multiplier (Q0.31 fixed-point) |
| SHIFT | 0x08 | Right shift amount |
| OUT | 0x0C | Result (read) |
| CTRL | 0x10 | Write `1` → sample result |

**Phép tính bên trong (combinational):**
```verilog
// SaturatingRoundingDoublingHighMul:
wire signed [63:0] ab_64 = raw_val * multiplier;         // 32×32 → 64 bit
wire signed [31:0] nudge = (ab_64 >= 0) ? (1<<30) : (1 - (1<<30));
wire signed [31:0] ab_x2_high32 = (ab_64 + nudge) >>> 31; // lấy 32 bit cao, rounded

// RoundingDivideByPOT:
wire [31:0] mask = (1 << shift) - 1;
wire [31:0] remainder = ab_x2_high32 & mask;
wire [31:0] threshold = (mask >> 1) + (ab_x2_high32 < 0 ? 1 : 0);
wire signed [31:0] result = (ab_x2_high32 >>> shift) + ((remainder > threshold) ? 1 : 0);
```

Phần cứng này thực hiện **1 phép nhân 64-bit + rounding + shifting** — nếu làm bằng phần mềm trên RV32IM sẽ cần ~50–100 cycles (vì phải xử lý 64-bit arithmetic trên CPU 32-bit).

### 5.5 Accelerator #4: Depthwise Convolution 3×3 (`my_dw_conv_accel`)

**Mục đích:** Tích chập depthwise — cùng cấu trúc phần cứng với conv_accel (5×5→3×3), nhưng **cách sử dụng từ software khác hoàn toàn**.

| Aspect | Standard Conv Accel | DW Conv Accel |
|--------|-------------------|---------------|
| Gọi bao nhiêu lần / output tile | `N` lần (N = input channels) | **1 lần** |
| Cross-channel accumulation | Có (software tích lũy qua channels) | **Không** (mỗi channel độc lập) |
| Output = ? | `Σ_ic conv(input[ic], kernel[oc][ic])` | `conv(input[ic], kernel[ic])` |

> **Hardware giống hệt** conv_accel, điểm khác biệt hoàn toàn ở **software orchestration pattern**.

**Software flow cho DW1 3×3 stride-1 (accelerated):**
```c
for (in_channel = 0..15) {
    // Load 3×3 kernel cho channel này (9 giá trị)
    for (ky, kx) DW_CONV_ACCEL_KER[ky*3+kx] = filter[in_channel*9 + ky*3+kx];
    
    for (tile_y, tile_x — tiling output thành 3×3 tiles) {
        // Load 5×5 input tile cho channel này
        DW_CONV_ACCEL_IMG[...] = input[in_channel][...] + input_offset;
        
        // Trigger
        DW_CONV_ACCEL_CTRL = 1;
        
        // Đọc 3×3 output + bias + quantize → TRỰC TIẾP ra int8
        // KHÔNG cần tích lũy cross-channel!
    }
}
```

**DW2, DW3 (stride-2):** Không có accelerator — dùng software optimized path (vì stride-2 thay đổi tiling pattern).

### 5.6 Accelerator #5: Pointwise Convolution Dot Product (`my_pw_conv_accel`)

**Mục đích:** Tính dot product `result = Σ(input[i] × weight[i])` cho i = 0..depth−1, với depth có thể cấu hình lên đến 64. Đây là phép toán lõi của Pointwise Conv 1×1.

**Register Map (base 0x02000400, 1KB window):**

| Register | Offset | Index | Mô tả |
|----------|--------|-------|-------|
| `INPUT[0..63]` | 0x000–0x0FC | 0–63 | Input vector (int32, pre-offset) |
| `WEIGHT[0..63]` | 0x100–0x1FC | 64–127 | Weight vector (int32) |
| `DEPTH` | 0x200 | 128 | Số phần tử dot product (1–64) |
| `CTRL` | 0x204 | 129 | Write `1` → trigger compute |
| `RESULT` | 0x208 | 130 | Read: kết quả dot product |

**Phép tính (khi CTRL = 1):**
```verilog
// Blocking accumulation → non-blocking output register
temp_sum = 0;
for (j = 0; j < 64; j = j + 1) begin
    if (j < depth_reg)
        temp_sum = temp_sum + input_buf[j] * weight_buf[j];
end
result_reg <= temp_sum;
```

Tính **song song** (unrolled loop trong 1 clock cycle): **lên đến 64 phép nhân + 6-level adder tree**.

**Software flow cho PW1 1×1 [16→32]:**
```c
*PW_CONV_ACCEL_DEPTH = 16;  // dot product length = input_depth

for (p = 0; p < 784; ++p) {                    // 28×28 spatial positions
    // Load input vector 1 lần (16 channels tại vị trí p)
    for (ic = 0..15)
        PW_CONV_ACCEL_INPUT[ic] = input[ic*784 + p] + input_offset;
    
    for (oc = 0..31) {                           // 32 output channels
        // Load weight vector (16 values cho output channel oc)
        for (ic = 0..15)
            PW_CONV_ACCEL_WEIGHT[ic] = filter[oc*16 + ic];
        
        *PW_CONV_ACCEL_CTRL = 1;                 // trigger → 1-cycle compute
        
        int32_t acc = *PW_CONV_ACCEL_RESULT;     // đọc dot product
        acc += bias[oc];                          // add bias
        acc = MultiplyByQuantizedMultiplier(...); // quantize (qua quant accel)
        output[oc*784 + p] = clamp(acc, -128, 127);
    }
}
```

> **Key optimization:** Input vector loaded **1 lần** per spatial position, reused across **tất cả output channels**.

---

## 6. Firmware: Boot & Inference Pipeline

### 6.1 Boot Sequence

```asm
# start.s — Entry point tại địa chỉ 0x00000000
start:
    li sp, 0x00040000    # Stack pointer = đỉnh 256KB RAM
    call main            # Gọi hàm main() trong C
inf_loop:
    j inf_loop           # Loop vô tận nếu main() return
```

### 6.2 Linker Script (`sections.lds`)

```
MEMORY {
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00040000
}

SECTIONS {
    .text   : { *(.text.start) *(.text*) } > ram    /* Code */
    .data   : { *(.data*) *(.rodata*) } > ram        /* Initialized data + constants */
    .bss    : { *(.bss*) *(COMMON) } > ram           /* Uninitialized data */
}
```

> Stack grows downward từ `0x40000`. Code + data grows upward từ `0x00000`. Firmware tổng cộng ~108 KB (chủ yếu là model weights + test images).

### 6.3 UART Output Helpers

CPU không có OS → tự implement I/O:

```c
void putchar(char c) {
    if (c == '\n') REG_UART_DATA = '\r';  // CR+LF cho terminal
    REG_UART_DATA = c;
}

void print_dec(int val) {
    // Chia lấy dư cho 10, dùng software division (vì không có HW divider)
    // Hàm div10() dùng bit-shifting: O(32) iterations
}
```

### 6.4 Software Multiplication Fallback

Dù CPU có `ENABLE_MUL(1)`, firmware vẫn định nghĩa `__mulsi3` và `__muldi3` (32-bit và 64-bit multiply) vì compiler flag `-nostdlib` không link libgcc:

```c
int __mulsi3(int a, int b) {
    // Shift-and-add multiplication
    int res = 0;
    unsigned int ua = (a < 0) ? -a : a;
    unsigned int ub = (b < 0) ? -b : b;
    while (ub > 0) {
        if (ub & 1) res += ua;
        ua <<= 1; ub >>= 1;
    }
    return ((a < 0) ^ (b < 0)) ? -res : res;
}
```

> Với `ENABLE_MUL(1)`, compiler sẽ emit `mul` instruction trực tiếp. `__mulsi3` chỉ là fallback nếu compiler chọn gọi library function thay vì inline instruction.

### 6.5 Cycle Counter

```c
static inline unsigned int rdcycle(void) {
    unsigned int cycle;
    __asm__ volatile ("rdcycle %0" : "=r"(cycle));
    return cycle;
}
```

Đọc hardware cycle counter (RISC-V CSR `cycle`) để benchmark từng layer.

### 6.6 Inference Pipeline

```c
int main() {
    REG_LEDS = 0x01;  // Báo hiệu đang chạy
    
    for (img_idx = 0; img_idx < 1; img_idx++) {
        // ---- Layer 1: Conv0 3×3 [1→16] ----
        Conv2D_TFLM(image, ..., buf_a, ...);      // buf_a = 28×28×16
        
        // ---- Layer 2: DW1 3×3 [16ch s1] ----
        DepthwiseConv2D_TFLM(buf_a, ..., buf_b, ...);  // buf_b = 28×28×16
        
        // ---- Layer 3: PW1 1×1 [16→32] ----
        Conv2D_TFLM(buf_b, ..., buf_a, ...);      // buf_a = 28×28×32
        
        // ... DW2 → PW2 → DW3 → PW3 (ping-pong giữa buf_a và buf_b)
        
        // ---- Layer 8: GAP [7×7×64 → 64] ----
        GlobalAveragePool_TFLM(buf_a, ..., gap_output, ...);
        
        // ---- Layer 9: FC [64→10] ----
        FullyConnected2D_TFLM(gap_output, ..., fc_output, ...);
        
        // Kết quả
        predicted = argmax(fc_output);
    }
    
    if (all_correct) REG_LEDS = 0xAA;  // SUCCESS
    else             REG_LEDS = 0xFF;  // PARTIAL
}
```

**Double buffering:** Dùng `buf_a[28×28×32]` và `buf_b[28×28×32]` ping-pong — output của layer trước là input của layer sau, luân phiên giữa 2 buffer.

---

## 7. Phần Mềm Deep Learning Operations

### 7.1 Dispatch Logic trong `Conv2D_TFLM`

```c
#ifndef NATIVE_RUN
    if (3×3 && stride 1)
        → Hardware accelerated path (my_conv_accel)
    else if (1×1 && stride 1)
        → Hardware accelerated path (my_pw_conv_accel)    ← PW conv accelerator
    else
#endif
    {
        → Generic software path (any kernel, any stride)
    }
```

### 7.2 Dispatch Logic trong `DepthwiseConv2D_TFLM`

```c
#ifndef NATIVE_RUN
    if (3×3 && stride 1 && depth_mult 1)
        → Hardware accelerated path (my_dw_conv_accel)
    else if (3×3 && stride 2 && depth_mult 1)
        → Optimized software path (stride-2 specific)
    else
#endif
    {
        → Generic software path
    }
```

### 7.3 GlobalAveragePool — Software Division

PicoRV32 không có hardware divider (`ENABLE_DIV=0`), nên GAP dùng **shift-and-subtract division**:

```c
// Chia acc cho num_elements (= H × W)
int32_t avg = 0, remainder = abs_acc;
for (int bit = 31; bit >= 0; --bit) {
    int32_t shifted = num_elements << bit;
    if (shifted > 0 && remainder >= shifted) {
        remainder -= shifted;
        avg |= (1 << bit);
    }
}
// Rounding: nếu remainder >= num_elements/2 thì avg++
```

### 7.4 Data Layout — Channel-First (CHW)

Toàn bộ dữ liệu feature map dùng layout **Channel-First** (planar):

```
data[channel * H * W + y * W + x]
```

Ưu điểm: truy cập tuần tự theo channel cho DW conv (mỗi channel xử lý liên tục). Nhược điểm: PW conv phải nhảy `spatial_size` bytes giữa các channel tại cùng vị trí spatial.

### 7.5 `#ifndef NATIVE_RUN` — Dual-Mode Code

Code được thiết kế để compile 2 cách:
1. **Target mode** (default): Dùng hardware accelerator qua MMIO
2. **Native mode** (`-DNATIVE_RUN`): Compile trên PC để verify correctness bằng phần mềm thuần — file `verify_native.c`

---

## 8. Memory Map & Bus Protocol

### 8.1 Memory Map tổng hợp

```
0x00000000 ┌──────────────────────────────┐
           │                              │
           │        256 KB SRAM            │
           │   (Code + Data + Stack)       │
           │                              │
0x0003FFFF └──────────────────────────────┘

0x02000004 ┌──────────────────────────────┐ UART Divider
0x02000008 │                              │ UART Data
0x02000010 │  Multiplier Accel (16 bytes) │
0x0200001F └──────────────────────────────┘
0x02000100 ┌──────────────────────────────┐
           │  Conv 3×3 Accel (256 bytes)  │
0x020001FF └──────────────────────────────┘
0x02000200 ┌──────────────────────────────┐
           │  Quant Accel (256 bytes)     │
0x020002FF └──────────────────────────────┘
0x02000300 ┌──────────────────────────────┐
           │  DW Conv Accel (256 bytes)   │
0x020003FF └──────────────────────────────┘
0x02000400 ┌──────────────────────────────┐
           │  PW Conv Accel (1 KB)        │
           │  INPUT[64] + WEIGHT[64]      │
           │  + DEPTH + CTRL + RESULT     │
0x020007FF └──────────────────────────────┘

0x03000000 ┌──────────────────────────────┐ LED Register
           └──────────────────────────────┘
```

### 8.2 Address Decoding

```verilog
wire ram_sel            = mem_valid && (mem_addr < 262144);           // < 256KB
wire led_sel            = mem_valid && (mem_addr == 32'h03000000);
wire uart_dat_sel       = mem_valid && (mem_addr == 32'h02000008);
wire accel_sel          = mem_valid && (mem_addr[31:4] == 28'h0200001);
wire conv_accel_sel     = mem_valid && (mem_addr[31:8] == 24'h020001);   // 256B
wire quant_accel_sel    = mem_valid && (mem_addr[31:8] == 24'h020002);   // 256B
wire dw_conv_accel_sel  = mem_valid && (mem_addr[31:8] == 24'h020003);   // 256B
wire pw_conv_accel_sel  = mem_valid && (mem_addr[31:10] == 22'h008001);  // 1KB
```

### 8.3 MMIO Transaction Timing

```
Clock:    ___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___
           T0      T1      T2      T3
           
mem_valid: ________/‾‾‾‾‾‾‾‾‾‾‾‾‾\____________  CPU issues request
mem_addr:  --------< ADDRESS     >--------------
mem_wdata: --------< DATA        >--------------
mem_wstrb: --------< STROBE      >--------------

xxx_sel:   ________________/‾‾‾‾‾‾‾‾\__________  Address decoded
xxx_ready: ________________________/‾‾\________  Ready after 1 cycle
mem_rdata: ________________________<RESP>______  Data available

Total: 2 clock cycles per MMIO access
```

---

## 9. Kết Quả Benchmark

### 9.1 Cycle Count per Layer (với tất cả accelerator)

| # | Layer | Input → Output | Cycles | Accelerator |
|---|-------|---------------|--------|-------------|
| 1 | Conv0 3×3 | 28×28×1 → 28×28×16 | **7,738,739** | ✅ Conv HW |
| 2 | DW1 3×3 s1 | 28×28×16 → 28×28×16 | **6,658,976** | ✅ DW Conv HW |
| 3 | PW1 1×1 | 28×28×16 → 28×28×32 | **16,744,574** | ✅ PW Conv HW |
| 4 | DW2 3×3 s2 | 28×28×32 → 14×14×32 | **10,869,269** | ❌ Software (stride-2) |
| 5 | PW2 1×1 | 14×14×32 → 14×14×48 | **10,676,131** | ✅ PW Conv HW |
| 6 | DW3 3×3 s2 | 14×14×48 → 7×7×48 | **3,990,023** | ❌ Software (stride-2) |
| 7 | PW3 1×1 | 7×7×48 → 7×7×64 | **5,019,251** | ✅ PW Conv HW |
| 8 | GAP | 7×7×64 → 64 | **187,380** | ❌ Software |
| 9 | FC | 64 → 10 | **50,824** | ❌ Software |
| | **Total** | | **62,071,887** | |

### 9.2 PW Conv Accelerator Speedup

| Layer | Before (software) | After (HW accel) | Speedup |
|-------|-----------------:|----------------:|--------:|
| PW1 1×1 [16→32] | ~35,023,651 | **16,744,574** | **~2.1×** |

> Speedup ~2× (thay vì lý thuyết 6-8×) vì **bottleneck chuyển sang MMIO data loading**: mỗi dot product cần 16 weight writes (4 cycles mỗi write) qua bus, trong khi phần cứng compute chỉ 1 cycle.

### 9.3 Phân bố thời gian

```
Conv0  ████████████░░░░░░░░░░░░░░░░░░░░░  12.5%
DW1    ██████████░░░░░░░░░░░░░░░░░░░░░░░░  10.7%
PW1    ██████████████████████████░░░░░░░░░  27.0%  ← bottleneck lớn nhất
DW2    █████████████████░░░░░░░░░░░░░░░░░░  17.5%
PW2    █████████████████░░░░░░░░░░░░░░░░░░  17.2%
DW3    ██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░   6.4%
PW3    ████████░░░░░░░░░░░░░░░░░░░░░░░░░░   8.1%
GAP    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0.3%
FC     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0.1%
```

### 9.4 Classification Output

```
=== Image 0 (Target: 7) ===
  Scores: [7, 33, -13, -27, 19, 1, -43, 115, -44, 45]
  >> Predicted: 7 | Total: 62,071,887 cycles  ✅
```

Score cao nhất = **115** tại index **7** → Dự đoán đúng chữ số **7**.

### 9.5 Simulation Stats

| Metric | Value |
|--------|-------|
| CPU Clock | 50 MHz (20ns period) |
| Total Cycles | 62,071,887 |
| Inference Time (simulated) | ~1.24 seconds @ 50MHz |
| Sim Wall Time (Icarus Verilog) | ~20 minutes |
| Sim Time Units | 1,243,418,010,000 ps |

---

## 10. Cấu Trúc File Dự Án

```
MyTinyMobileNetSoC/
│
├── ── Hardware (Verilog) ──────────────────────────────────────
│   ├── tb.v                      # Testbench: clock, reset, UART rx, timeout
│   ├── my_soc.v                  # Top-level SoC: CPU + RAM + peripherals + accel
│   ├── picorv32.v                # PicoRV32 CPU core (3rd-party, open-source)
│   ├── simpleuart.v              # UART TX/RX peripheral
│   ├── my_accel.v                # Simple 32×32 multiplier accelerator
│   ├── my_conv_accel.v           # 2D Conv 3×3 accelerator (5×5 tile → 3×3 output)
│   ├── my_quant_accel.v          # Quantization (SaturatingRoundingDoubling...)
│   ├── my_dw_conv_accel.v        # Depthwise Conv 3×3 accelerator
│   └── my_pw_conv_accel.v        # Pointwise Conv dot product accelerator
│
├── ── Firmware (C/ASM) ────────────────────────────────────────
│   ├── start.s                   # Entry point: set stack, call main
│   ├── sections.lds              # Linker script: memory layout
│   ├── main_tinymobilenet.c      # Main: inference pipeline, UART I/O
│   ├── dl_ops.c                  # Conv2D, DepthwiseConv2D, GAP, FC implementations
│   ├── dl_ops.h                  # Function prototypes
│   ├── quantize.c                # Software quantization helpers (native fallback)
│   └── quantize.h                # Quantization function prototypes
│
├── ── Model Data (auto-generated) ─────────────────────────────
│   ├── tinymobilenet_model_data.c  # Weights, biases, quant params (C arrays)
│   ├── tinymobilenet_model_data.h  # Extern declarations
│   └── mnist_test_images.h         # Test images + labels (C arrays)
│
├── ── ML Pipeline (Python) ────────────────────────────────────
│   ├── train_model.py              # Train float → quantize to int8 TFLite
│   ├── generate_model_data.py      # .tflite → C source code extraction
│   ├── extract_mnist_test.py       # MNIST test set → C header
│   └── debug_tflite.py             # TFLite model inspection utility
│
├── ── Model Files ─────────────────────────────────────────────
│   ├── tinymobilenet_mnist_float.keras   # Float Keras model
│   └── tinymobilenet_mnist_quant.tflite  # Quantized int8 TFLite model (~21KB)
│
├── ── Verification ────────────────────────────────────────────
│   ├── verify_native.c             # Native PC verification (no hardware accel)
│   └── verify_native               # Compiled native binary
│
├── ── Build ───────────────────────────────────────────────────
│   ├── Makefile                    # Build system
│   ├── firmware.elf                # Compiled firmware (ELF)
│   ├── firmware.hex                # Verilog hex for $readmemh
│   └── sim.vvp                     # Compiled Icarus Verilog simulation
│
└── ── Build Commands ──────────────────────────────────────────
      make              # Build firmware + Verilog → run simulation
      make clean        # Remove build artifacts
      make pipeline     # Full: train → generate → extract → build → simulate
```

### Build Flow

```
┌─────────┐     ┌──────────────┐     ┌───────────┐     ┌──────────┐
│ start.s │     │ main_*.c     │     │ dl_ops.c  │     │ model    │
│         │     │              │     │           │     │ _data.c  │
└────┬────┘     └──────┬───────┘     └─────┬─────┘     └────┬─────┘
     │                 │                   │                │
     └────────┬────────┴──────────┬────────┘                │
              │                   │                         │
              ▼                   ▼                         │
     ┌─────────────────────────────────────────────────┐    │
     │  riscv32-unknown-elf-gcc -march=rv32im          │◄───┘
     │  -ffreestanding -nostdlib -O2 -T sections.lds   │
     └───────────────────┬─────────────────────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │ firmware.elf │
                  └──────┬───────┘
                         │ objcopy -O verilog
                         ▼
                  ┌──────────────┐
                  │ firmware.hex │
                  └──────┬───────┘
                         │
     ┌───────────────────┼───────────────────────────────┐
     │                   │                               │
     ▼                   ▼                               ▼
 ┌────────┐     ┌──────────────┐                  ┌──────────┐
 │ tb.v   │     │ my_soc.v     │     ...          │ accel .v │
 └───┬────┘     └──────┬───────┘                  └────┬─────┘
     │                 │                               │
     └────────┬────────┴──────────┬────────────────────┘
              │                   │
              ▼                   │
     ┌─────────────────────┐      │
     │  iverilog -o sim.vvp │◄────┘
     └──────────┬──────────┘
                │
                ▼
     ┌──────────────────┐
     │   vvp sim.vvp    │ ← Chạy simulation, output qua UART
     └──────────────────┘
```
