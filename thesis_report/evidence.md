# Thesis template audit and evidence register

Paths below are relative to the repository root. Audit and cleanup date: 2026-10-12. Repository paths below are the evidence references; no evidence artifacts are copied into the thesis directory.
This writing task changed thesis documents only; it did not rerun inference,
train models, build firmware, run RTL tests or launch Vivado.

## Authoritative template

- `thesis_report/main.tex`: `report`, 11 pt, A4; Vietnamese `vntex`.
  Existing geometry, title page, fancy headers/footers, caption configuration,
  line spacing and chapter style preserved. No template redesign.
- Chapters are included with `\input`, relative to `thesis_report/`, with
  extension omitted. Three existing chapter roots are
  `Contents/GioiThieuDeTai`, `Contents/CoSoLyThuyet`, and
  `Contents/CongTrinhNghienCuuLienQuan`. Their contents and nested files are
  unchanged. Chapter 4 reuses `Contents/PhuongPhap/PhuongPhap.tex` and its
  existing `GioiThieu.tex`/`KienTruc.tex` split. Chapter 5 is added as
  `Contents/ToiUu/ToiUu.tex` before the bibliography.
- Filenames use Vietnamese descriptive names, usually without accents;
  existing literature survey directories also have accented names/spaces.
- Images use explicit `Images/...` paths in `\includegraphics`. No
  `\graphicspath` or diagram generation was introduced. Existing solution
  images describe an obsolete proposal and are no longer included in Chapter 4.
  They are retained on disk.
- Figures use floats, centering and caption; tables use tabular, horizontal
  rules and the global caption style. New tables follow those conventions.
  New diagram locations use clearly labelled text-only boxes, not invented
  architecture illustrations or copied legacy diagrams.
- `Outro/TaiLieuThamKhao.tex`: `\nocite{*}`, `\bibliographystyle{plain}`,
  `\bibliography{mybib.bib}`. This is BibTeX, not biblatex/biber.
  `mybib.bib`, Outro files and the preamble remain unchanged. Existing bibliography
  entries were inspected, but no new or fabricated entries were added.
- No engine directive, build script or latexmk configuration was found in the
  template. Its vntex setup is consistent with pdfLaTeX + BibTeX; that is the
  proposed build sequence, not an explicitly specified template engine.

## PDF references read

Both PDFs were extracted with pypdf downloaded only into `/tmp/thesis_pdf_tools`.
Extracted reference text is temporary, outside the repository.

- `Capstone_Project__Demo_.pdf`: 59 PDF pages. Architecture/detail organization
  on PDF pp. 2–32; system on p. 32; waveform and implementation discussion
  through pp. 43–46; ZCU106 deployment and layer test setup on pp. 47–48.
  Used the sequence specification → interface → test cases → results → analysis,
  and placement of overview figures before module details and tables near discussion.
- `RISC_V_AIoT_Capstone_Project_Print_V1.pdf`: 138 PDF pages. Chapter 5 system
  overview at PDF p. 94; HW/SW development at p. 102; Chapter 6 evaluation
  starts p. 103; timing/resources and per-module analysis at pp. 112–121.
  Used separation of system design, verification, physical implementation and
  deployment narrative. Its Ultra96-V2/Alpha Accelerator claims were not imported.
- No Flash/Alpha processing matrix, PU array, systolic implementation,
  MaxPool/Softmax hardware, separate IMEM/DMEM, reported frequency or power
  from these PDFs is used as evidence for MyTinyMobileNetSoC.

## Quantitative and architectural claims

Let `T = RISCVAIoT/MyTinyMobileNetSoC/` and
`W = TinyMobileNet_RISCV_SoC_Walkthrough.md`.

| Claim family in thesis | Evidence and exact location | Interpretation / limitation |
|---|---|---|
| Network dimensions, all nine operators, 64 GAP channels, 10 FC outputs; Conv/DW/PW stride | `T/main_tinymobilenet.c`, layer calls and dimension arrays; `T/dl_ops.c`, dispatch predicates; `W` §3.1, §6.6 | Current implementation, not full MobileNetV2; output scores before Softmax |
| Standard, DW, PW, GAP and FC equations; MAC-count formulas | `T/dl_ops.c`, `Conv2DLevel4`, `DepthwiseConv2D_TFLM`, `GlobalAveragePool`, `FullyConnected`; algebraic sums over kernel/channel ranges | Mathematical operation counts, not cycle measurements; literature citation TODO retained |
| 256 KiB / 65,536 × 32 RAM, address 0–0x3FFFF, reset PC 0, stack 0x40000 | `T/my_soc.v`, RAM declaration and PicoRV32 parameters; `T/start.s`; `T/sections.lds`; `W` §§2.1–2.2, 6.1–6.2 | Shared code/data RAM; downward stack; no claim of stack occupancy measurement |
| RV32IM compiler target, O2, ilp32, no DIV/IRQ/compressed | `T/Makefile` flags; `T/my_soc.v` CPU parameters; defaults in `T/picorv32.v` | MUL enabled, DIV disabled: not all M instructions are supported |
| MMIO ranges for RAM/UART/multiply/Conv/Quant/DW/PW/LED | `T/my_soc.v`, address selection expressions; `W` §8.1 | Byte address windows; two UART registers, five compute peripherals |
| No DMA, multiplier unused, CHW/int8/int32, CPU orchestration | `T/my_soc.v` module ports; `T/dl_ops.c`; `T/main_tinymobilenet.c`; `T/evaluation/CPU_BASELINE.md`, accelerator audit | Shared RAM is CPU-accessed; accelerator operands in 32-bit registers |
| Conv 25 input / 9 kernel / 9 result registers; word indices 0–24/28–36/40–48, CTRL 60; 5×5→3×3 | `T/my_conv_accel.v`, storage, write and read logic | Clocked result of combinational arithmetic expressions, no systolic array; sticky done until reset |
| Quant register offsets 0/4/8/C/10; signed 32×32→64; high divide 2^31; five transactions; signed shift convention | `T/my_quant_accel.v`; `T/dl_ops.c`, `MultiplyByQuantizedMultiplier*` | Clamp and output offset on CPU, output register int32 |
| INT8 bounds [-128,127], native division vs RTL arithmetic shift, incomplete saturation | `T/main_tinymobilenet.c` activation bounds; `T/quantize.c`, `SaturatingRoundingDoublingHighMul`; `T/my_quant_accel.v`; `T/evaluation/CPU_BASELINE.md`, correctness limits | No universal bit-exactness; C overflow/left-shift behavior has compiler-dependent limits |
| DW2 exact shape, 5×5 patch→2×2 outputs at indices 0/2/6/8; DW3 CPU | `T/dl_ops.c`, exact DW2 predicate and selected results; `T/my_dw_conv_accel.v`; `W` §9.6 Level 4 | Overrides obsolete guidance that all stride-2 DW is CPU; only exact DW2 shape offloaded |
| PW buffer 64 lanes, batch 4 banks, 4 compute edges, packed 4 bytes/word; legacy bank 32-bit | `T/my_pw_conv_accel.v`, buffers, tree, batch state and packed write aliases; `T/my_soc.v`, rvalid gating | Shared datapath computes banks serially, publishes results together |
| Seven total cycle counts 62,071,887 / 55,395,889 / 46,579,875 / 44,156,359 / 36,208,913 / 31,135,055 / 26,523,121 | `W` §9.6 version table | Historical integrated simulation; intermediate raw logs/build hashes were not located |
| 57.27% reduction, 2.3403× optimization speedup | `(1 − 26,523,121 / 62,071,887) × 100`, `62,071,887 / 26,523,121`; `W` §9.6 | Against accelerated baseline, not CPU-only |
| Level 1 three PW timings, unroll by four, DEPTH once/layer, unchanged non-PW timings | `W` §9.6 Level 1 and PW timing table; current scalar remainder in `T/dl_ops.c` | Historical firmware-only change |
| Level 2 write counts 401,408→100,352 / 301,056→75,264 / 150,528→37,632; 75% reduction; three PW cycle counts | `W` §9.6 Level 2 tables; packed aliases in `T/my_pw_conv_accel.v`; aligned loading helpers in `T/dl_ops.c` | Counts of WEIGHT writes, not all MMIO; alias-safe aligned word load and byte fallback |
| Level 3 PW counts 8,393,456 / 4,286,581 / 1,810,193; two vs five CPU sample edges, three extra stalls; Conv0 7,712,627→7,775,776 | `W` §9.6 Level 3 and Non-PW timings | Read-stall observations distinct from four-cycle compute latency; historical codegen effect |
| Level 4 DW2 10,869,269→3,994,547; DW1 6,658,976→6,421,895; DW3 3,990,023→3,155,797 | `W` §9.6 Level 4 table; current `DWStride2CPU` helper | Software reuse plus compiler-codegen changes, no added RTL |
| Level 5 cache 32×128 bit =4096 bit=512 byte; 784 positions; weight word loads 100,352→128; PW1 8,393,456→3,318,925; 60.46% | `W` §9.6 Level 5; `T/my_pw_conv_accel.v`, `cache_rows/cache_loaded`; `T/dl_ops.c`, `CachedPW1Hardware` | Capacity is logical payload; excludes metadata/control and is not physical resource delta |
| Level 6 INPUT writes 40,000→2,500; valid input RAM loads 33,856→2,116; RESULT reads 14,400→12,544; Quant 62,720 unchanged | `W` §9.6 Level 6 traffic table; `T/dl_ops.c`, `TileConv0Hardware` | Current code supports schedule; historical counters not rerun |
| Output stores 12,544 unchanged | `28×28×16=12,544`; same valid output tensor in `T/dl_ops.c`; `W` §9.6 Level 6 boundary/store description | Derived tensor-element count, not independent measured bus-store log |
| Conv0 instruction counts 1,471,205→566,991 | User task specification ONLY; no matching raw counter log or evaluation document located | **Raw-log evidence unavailable. Removed from Chapter 5**, including the results table and prose; not found in walkthrough or current evaluation documentation. Do not reintroduce without a primary measurement source |
| Level 6 Conv0 7,776,032→3,163,926; PW dispatcher +28/+57/+57; final per-layer table | `W` §9.6 Level 6 table; `T/evaluation/CPU_BASELINE.md`, Level 6 reference definition | PW1 final 3,318,953 differs from Level 5 3,318,925 |
| Score vector [7,33,-13,-27,19,1,-43,115,-44,45], prediction/label 7 | `W` §9.6 Correctness; `T/evaluation/CPU_BASELINE.md`, Measured result | Historical all-level equivalence on single image; not TFLite/RTL proof on all inputs |
| CPU-only 259,218,212; 9.7733×; GCC 16.1.0, Verilator 5.051; same configuration and compute MMIO prohibition | `T/evaluation/CPU_BASELINE.md`; `T/evaluation/run_cpu_baseline.py`; `T/evaluation/CPU_BASELINE.md`, Measured result (recorded tool versions) | Generic unoptimized CPU kernels, quantization semantics differ; speedup combines SW and HW improvements |
| Current LED policy vs historical one-image/100 issue | `T/main_tinymobilenet.c`, `test_count/tested_count` and final comparison; `W` §9.6 historical LED note | Current reporting fixed; keep historical timing provenance separate |
| Post-route 8.875 ns period, +0.056 ns setup WNS, Vivado 2024.1, device, worst path bank→result | `T/fpga/zcu106/reports/20261011_221527_22836_8p875ns/metadata.txt`, `status.txt`, `post_route/timing_summary.rpt`, `post_route/worst_setup_path.rpt` | Current final design; no matched pre/post-cache resource/timing delta; not board boot or global Fmax proof |
| SoC post-route completed without pins/RAM firmware/inference bitstream; deployment A0 clock/reset/LED bitstream generated | `T/fpga/zcu106/README.md`; run metadata/status; `T/fpga/zcu106/deployment/README.md`, Local verification; `T/fpga/zcu106/deployment/build/status.txt` | Smoke bitstream not programmed or board-tested; physical LED test and TinyMobileNet inference pending |
| Level 6 scope freeze | User instruction for this cleanup: freeze performance work after Level 6 and prioritize verification, FPGA implementation, deployment and thesis completion | Project scope decision, not a reconstructed historical explanation or failed Level 7 result |

## Evidence cleanup and source availability

The seven task-created files in `thesis_report/evidence/` were removed and the
empty directory removed. Only this handwritten evidence register is retained.
CPU-only figures now refer to `T/evaluation/CPU_BASELINE.md`; Level 1–6 figures
refer to `W` §9.6. Vivado statements refer to original report directories under
`T/fpga/zcu106/reports/`; smoke-test completion refers to the original
`T/fpga/zcu106/deployment/build/status.txt` and deployment README.

No repository-original raw CPU result JSON or complete historical Level 1–6
simulation log set was found during this cleanup. Temporary results under `/tmp`
are not used as the thesis provenance and were not relocated into the repository.
The documentation and walkthrough support the retained numbers, but complete
primary log/build provenance for the historical cycle comparison remains
unavailable in the repository. The Conv0 instruction-count pair is unsupported
by either document and has been removed from the chapter.

## Current-source review clarifications

- Re-read all seven requested RTL/firmware files plus linker/startup and native
  quantizer. Checked chapter claims against actual branches and assignments,
  rather than comments that still describe older behavior.
- DW1 uses hardware for 3×3, stride 1, depth multiplier 1. Exact DW2 geometry
  uses hardware at stride 2 with result indices 0/2/6/8. DW3 uses `DWStride2CPU`
  accumulation and hardware requantization. Current DW2/DW3 calls pass zero
  left/top padding; out-of-range right/bottom taps supply literal zero.
- DW2 hardware predicate checks kernel, stride, depth multiplier and input/output
  shape. Padding is a coordinate argument, not a further predicate condition.
- PW1 cache dispatch requires 28×28 spatial input/output, 16→32 channels,
  1×1 kernel, stride 1 and zero padding. Cached computation fixes depth at 16;
  ordinary batch snapshots DEPTH. Result banks update over four compute edges,
  then become readable together. `rvalid` stalls only BATCH_RESULT reads.
- Cache reset invalidates the bitmap/results without resetting cache payload.
  PW2/PW3 remain on non-cache batch processing.
- RAM has registered reads/byte writes; reset clears ready, not RAM contents.
  Main alternates `buf_a`/`buf_b`; GAP/FC have separate output buffers.
- GAP averages offset-adjusted values, using shift/subtract division and rounding
  magnitude before restoring sign; it then requantizes, adds offset and clamps.
  FC performs software accumulation/bias and hardware requantization.
- Quant has no output INT8 clamp; native C high division truncates toward zero,
  RTL shifts arithmetically, and saturation/overflow limits remain. No mutual
  native/RTL/TFLite bit-exactness is asserted.
- Speedups remain distinct: accelerated baseline→Level 6 = 2.3403×;
  generic RV32 CPU-only→Level 6 = 9.7733×.
- SoC evaluation reached post-route; A0 bitstream was generated only for an
  independent smoke test. Physical programming, LED observation and TinyMobileNet
  board inference remain pending, as stated in the original deployment sources.

## Build and validation

Expected command sequence, from `thesis_report/`:

```sh
pdflatex -interaction=nonstopmode -halt-on-error main.tex
bibtex main
pdflatex -interaction=nonstopmode -halt-on-error main.tex
pdflatex -interaction=nonstopmode -halt-on-error main.tex
```

No pdflatex, xelatex, lualatex, latexmk or bibtex executable is installed in this
session. Compilation could not run. No LaTeX packages or system tools were
installed. A static check covers recursive includes, image-file existence,
new chapter brace/environment balance, duplicate labels and new references.
This does not establish page layout, float placement, font availability, absence
of overfull boxes or successful bibliography rendering.

## Outstanding review

- Five diagram locations: network, SoC, PW datapath, inference firmware flow,
  and Conv0 before/after scheduling. Each is visibly labelled a placeholder.
- Two `% TODO: literature citation` comments: depthwise-separable convolution
  theory and affine quantization. No new unresolved `\cite` keys were introduced.
- Conv0 instruction-count pair lacks original measurement evidence and is excluded from Chapter 5.
- Historical optimization build/log identities need primary-source archival for reproducibility. No historical reason for stopping is asserted; the user-directed scope freeze is stated instead.
- Final typeset Vietnamese wording, line breaks, table widths and float positions
  require review after a real pdfLaTeX/BibTeX build.

### Final cleanup validation (2026-10-12)

Validation results are recorded below after running the static review. Compilation
remains unavailable because no LaTeX engine is installed; static checks do not
establish rendered pagination, table widths, float placement or font rendering.

- `git diff --check`: exit 0. Because the thesis directory was already untracked,
  additionally checked new chapter files for trailing whitespace; none found.
- Recursive active LaTeX graph: 29 files; token-aware brace/environment checks
  pass, including unchanged main template. All input/image paths exist, no
  duplicate labels, no unresolved references or citation keys. `LastPage` is
  provided by the existing package. Five figure TODOs and two literature TODOs
  remain in Chapters 4–5.
- SHA256 comparison against the pre-cleanup snapshot: no tracked technical file
  or Chapter 1–3 file changed. Cleanup edits are limited to the Chapter 4
  introduction/architecture, Chapter 5 and this note; seven copied evidence
  files were deleted. No new file was created during cleanup.
- Relative to the pre-writing template, the only modified original files are
  `main.tex` and `Contents/PhuongPhap/{PhuongPhap,GioiThieu,KienTruc}.tex`;
  the only created files remaining are `Contents/ToiUu/ToiUu.tex` and
  `evidence.md`. Original formatting and Chapters 1–3 remain unchanged.
- Chapters 4–5 are ready for human technical/editorial review. They are not
  submission-ready until diagrams, literature citations and rendered LaTeX
  validation are completed. Retained numerical results have repository
  documentation/walkthrough/report sources; historical raw simulation log and
  build completeness remains a reproducibility limitation.
- No commit made; no firmware, model, RTL, evaluation code or FPGA flow changed.
