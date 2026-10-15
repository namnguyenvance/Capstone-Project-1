# Thesis template audit and evidence register

Paths are relative to the repository root. Current audit: 2026-10-15.
This documentation pass did not rerun inference, train models, build firmware,
run RTL tests or launch Vivado. Evidence remains at its original source paths.

## Active template and document structure

- `thesis_report/main.tex`: `report`, 11 pt, A4, Vietnamese `vntex`;
  existing geometry, title-page styling, headers/footers, captions, line spacing
  and chapter style preserved. Navigation uses roman front matter and arabic
  main text, with cover anchors disabled to avoid duplicate PDF destinations.
- Chapters use relative `\input` paths. Chapters 1–3 roots are
  `Contents/GioiThieuDeTai`, `Contents/CoSoLyThuyet` and
  `Contents/CongTrinhNghienCuuLienQuan`. Chapter 1 ownership wording was updated;
  Chapters 2–3 are unchanged. Chapter 4 retains its `PhuongPhap` split and
  Chapter 5 remains `Contents/ToiUu/ToiUu.tex`.
- Five thesis-local TikZ figures are included directly; no placeholder artwork
  remains. Existing labels are retained. Legacy solution images stay on disk
  but are not included in Chapter 4.
- `Outro/TaiLieuThamKhao.tex` uses BibTeX `plain` with `mybib`, no wildcard
  nocite, and a linked bibliography TOC entry. The list of tables is enabled.
- Current pdfLaTeX/BibTeX build and layout findings are recorded at the end.

## PDF references read

Both reference PDFs were read via temporary text extracts; this final pass used
`pdftotext -layout`. Extracted reference text remains outside the repository.

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

## Reviewer-approved corrections — 2026-10-15

This entry supersedes earlier descriptions where the new reviewer corrections
provide additional evidence or more precise scope. No raw artifact was copied,
no new experiment was claimed, and no technical source was changed.

### 10k host accuracy provenance

- Approved reviewer/user findings supply the verified full-test accuracies:
  Float Keras 94.64%, TFLite INT8 94.42%, native C 94.33%, on 10,000 MNIST
  test images. These are host/model/native accuracies only. No prediction
  agreement is inferred from their differences; no 10k RTL claim is made.
- Reproduction procedure and environment: original repository
  `RISCVAIoT/MyTinyMobileNetSoC/evaluation/README.md` and
  `evaluation/evaluate_mnist.py`. The README records Windows Python 3.10.8,
  TensorFlow 2.18.0, Keras 3.7.0, NumPy 2.0.2 for references; WSL Python 3.14.4
  and GCC 15.2.0 for native; preprocessing and native arithmetic qualifications.
- The procedure emits `results.json`, `summary.txt`, `predictions.csv`, hashes,
  native log and disagreement records into an external output directory. It
  does not record these three final accuracy values in the checked-in README.
- Previously designated `/tmp/tmn_accuracy_10k/` is absent in this session.
  No repository-original raw accuracy results were located. Thus the numbers
  are reviewer-confirmed results, **not independently re-read from raw results
  during this editing pass**. Preserve/recover the original output at its source
  for primary-source reproducibility before final submission. Do not fabricate
  a repository log path or imply this limitation is fixed by the evaluation script.

### CPU-only and matched Level 6 provenance

- CPU-only source: `RISCVAIoT/MyTinyMobileNetSoC/evaluation/CPU_BASELINE.md`,
  especially Definition, Measurement/correctness limits and Measured result;
  executable procedure is `evaluation/run_cpu_baseline.py`.
  It records 259,218,212 cycles, GCC 16.1.0, Verilator 5.051, no-compute-MMIO
  assertion, score vector and measurement-boundary observations.
- Historical Level 6 source: root walkthrough §9.6; 26,523,121 total cycles and
  its nine layer counts. Their sum is 26,390,722; difference 132,399. GAP+FC
  fraction is `(187380+50824)/26390722*100 = 0.902605...%` of layer time.
- Current timing-boundary source: `main_tinymobilenet.c`, `total_start` before
  the Conv0 message and `total_end` after the FC cycle message. Argmax, printing
  scores/prediction and LED status are outside this interval. Each `layer_start`
  follows its announcement and each `layer_end` precedes its cycle printout.
  The 132,399-cycle difference has no independently measured UART/MMIO/setup
  decomposition; do not assign it all to one mechanism.
- Matched Level 6 provenance available from the earlier audit in this conversation:
  `/tmp/tmn_level6_matched/results.json`, `simulation.log`, tool-version files
  and `commands.json` were observed; summary total/layers matched historical
  Level 6, score vector and prediction matched the CPU-only run, and all recorded
  source SHA256 entries matched then-current sources. This was not a new run
  performed by the thesis task. The task-created copies were subsequently removed
  as requested. That external directory and `/tmp/tmn_cpu_baseline/` are now absent.
  No durable matched-run original was found in the repository; the old audit is
  a historical observation, not a currently re-verifiable raw result. The CPU
  baseline README itself explicitly describes its Level 6 reference as historical.
- Chapter 5 therefore bases the numerical comparison on the original CPU baseline
  documentation and walkthrough, while retaining the missing-log/build limitation.
  No invented matched-build identity or universal native/RTL equivalence is added.

### Timing sweep and source identity

Let `R = RISCVAIoT/MyTinyMobileNetSoC/fpga/zcu106/reports/`.

| Run directory under R | Original evidence | Status / allowed conclusion |
|---|---|---|
| `20261011_221527_22836_8p875ns/` | `post_route/utilization.rpt`, CLB table and primitives; `post_route/timing_summary.rpt`, Design Timing Summary; metadata/status/manifest | CLB LUTs 18,010; registers 10,805; RAMB36 64; DSP48E2 685; WNS +0.056 ns; WHS +0.012 ns. Highest tested timing-clean point in this sweep, not true Fmax or board validation. Final Level 6/current-design cost, not incremental cost of any one optimization. |
| `20261011_213352_14700_8p75ns/` | `status.txt`, `post_route/timing_summary.rpt` | Completed at 8.750 ns, setup WNS −0.242 ns; next completed tighter point fails setup. |
| `20261011_231608_8_8p8125ns/` | `status.txt`, `metadata.txt`, copied `evaluation.xdc` | Failed at synthesis-stage period assertion: clock period disagrees with metadata. No timing verdict; not a timing failure measurement and not an intermediate Fmax bound. |

Both completed runs' `rtl_manifest.txt` entries were checked using
`git hash-object RISCVAIoT/MyTinyMobileNetSoC/<filename>` in this pass. All eight
entries match current source in both runs:

| RTL file | Matching Git blob ID |
|---|---|
| `my_soc.v` | `76c9d55d6fcd54fda74e6ea144e5652c56a6b8d6` |
| `picorv32.v` | `c493c2d25b26478e7bc02562d714e272deb7071c` |
| `simpleuart.v` | `5ffef772ffe38d78ddda98a79a9f0db695274e88` |
| `my_accel.v` | `7419cfef7398d2d3d6ce07891b019d8f857c6ebe` |
| `my_conv_accel.v` | `e779e50fc6bad015a6121ddd89481ce5e63c74af` |
| `my_quant_accel.v` | `3ad47e497b245d1f7556339b981d09727836ccb2` |
| `my_dw_conv_accel.v` | `16c070a82837d460606d84e52ee62dc4a15fd509` |
| `my_pw_conv_accel.v` | `585719bdc1b8cfd9b41f61dcdfe6f8ce81b97735` |

These are the manifest's Git content hashes, not SHA256, firmware hashes or proof
of a bootable board image. Constraints/metadata, tool/device and completed stage
still determine interpretation. Physical TinyMobileNet validation remains pending.

### Architecture and historical-check qualifications

- Workload rationale and absence of MobileNetV2 inverted-residual/bottleneck
  blocks: `train_model.py`, model-building function; actual layer calls in
  `main_tinymobilenet.c`. The rationale is a thesis workload argument, not a
  claim of universal model optimality.
- Separate Conv/DW blocks: `my_conv_accel.v`, `my_dw_conv_accel.v`, separate
  instances/windows in `my_soc.v`, and distinct loops in `dl_ops.c`. Similar
  patch arithmetic supports a shared-versus-duplicated hardware trade-off;
  no undocumented historical rationale is asserted.
- DW3 coverage and PW1 lifetime: `dl_ops.c`, DW2 shape predicate,
  `DWStride2CPU`, `Conv2D_TFLM` and `CachedPW1Hardware`. Every PW1 invocation
  writes cache index 0 then preloads 128 words; no cross-image residency is used.
- PW tensor comparisons derived from current layer dimensions:
  PW1 `32*16=512` bytes / `28*28=784` positions;
  PW2 `48*32=1536` bytes / `14*14=196` positions;
  PW3 `64*48=3072` bytes / `7*7=49` positions.
  This is capacity/reuse opportunity, not measured benefit for unimplemented caches.
- Retained focused executable checks include `tb_pw_conv_accel.v`,
  `tb_pw_bus.v`, `tb_pw_cache.v`, `tb_dw2_mapping.v`, `verify_pw_firmware.c`,
  `verify_pw_cache.py`, `verify_dw2_firmware.c`/`.py` and the Makefile test targets.
  These support the existence of regression coverage, not a claim that this
  editing pass reran those tests or recovered all historical firmware versions.
- Root walkthrough §9.6 remains the documented Level 1–6 historical source.
  Full original logs/build identities for the series remain missing. Compiler,
  dispatcher and MMIO causal explanations are identified as recorded attribution
  or architectural inference, rather than independent cycle decompositions.

## Final whole-thesis corrections and current build — 2026-10-15

This is the current layout/build record. Earlier pagination, build-unavailable
statements and figure-placeholder checklists were removed because they no longer
represent the active document. Historical result provenance above is retained;
no missing raw evidence has been reconstructed or fabricated.

### Applied documentation corrections

- Added the Vietnamese abstract, with both cycle comparisons and the three host
  accuracy values; it distinguishes host accuracy from RTL testing, the tested
  timing point from true Fmax, and post-route evaluation from board validation.
- Chapter 1 now separates PicoRV32, inherited Conv/Quant and external ML/tools
  from the student's integration, firmware, DW/PW/MMIO, Level 1–6, evaluation
  methodology and FPGA preparation work. `cmp` confirmed that active
  `my_conv_accel.v` and `my_quant_accel.v` are byte-identical to their respective
  `MyLeNet5SoC` counterparts. This supports reuse, not identification of an
  original individual author. PicoRV32 is attributed through its existing citation.
- Added compact model-preparation context from `train_model.py`,
  `generate_model_data.py` and `extract_mnist_test.py`: float Keras on normalized
  MNIST, full INT8 TFLite with 200 training images for calibration, C export,
  input quantization and integer firmware. Training ReLU6/Softmax is explicitly
  distinguished from full INT8 firmware clamps and integer scores/argmax.
- Added section 5.12, concluding with measured outcomes, scope, FPGA trade-offs
  and remaining work, without new experiments or changed technical results.
- Added body callouts for Figures 4.1–4.4/5.1 and Tables 4.2/5.3–5.7. All active
  Chapter 4–5 figure/table labels now have explicit body references. Existing
  labels, including `-placeholder` suffixes, are unchanged; artwork is present.
- Removed `\nocite{*}`. The rendered bibliography contains exactly the ten cited
  keys. Protected title capitalization; corrected `he2021design` to `@article`
  with `journal` and `publisher`, keeping its existing author/year/volume/issue/
  article number/DOI. The former volume/number warning is gone. The IOP landing
  page/DOI was inaccessible during this pass; no new publication metadata was
  inferred from inaccessible content.
- Kiningham's legacy citation key is retained; year 2017 is supported by the
  Stanford Spring 2017 project index and linked report. Its source URL and the
  versioned Chipyard documentation URL are now visible with the plain style.
  Waterman is a technical report, with the Berkeley report number/institution.
  Verified primary references:
  - https://cs231n.stanford.edu/2017/reports.html
  - https://cs231n.stanford.edu/reports/2017/pdfs/116.pdf
  - https://chipyard.readthedocs.io/en/1.11.0/Customization/RoCC-Accelerators.html
  - https://www2.eecs.berkeley.edu/Pubs/TechRpts/2014/EECS-2014-54.html
- Preserved prior conceptual citations to Howard et al. (2017),
  https://arxiv.org/abs/1704.04861, and Jacob et al. (CVPR 2018),
  https://arxiv.org/abs/1712.05877. Neither changes firmware equivalence claims.
- Disabled cover page anchoring, used roman front matter and arabic main text,
  enabled the list of tables, and added a linked bibliography TOC entry.
  Official visual styling, margins, headers and chapter styles remain intact.
- Acknowledgements only: changed “học viên” to “sinh viên” and “tôi” to “em”.

### P0 manual confirmation: declaration and document identity

The reference `RISC_V_AIoT_Capstone_Project_Print_V1.pdf`, PDF page 2,
contains another student's declaration with broad originality and legal
commitments. No current official institutional declaration form was established.
Those commitments were not attributed to the current author. `LoiCamDoan.tex`
contains a visible pending-text notice and prepared date/signature structure.
The author must confirm the applicable wording, including reused components,
and supply date/signature before submission.

Cover references do not establish this student's official submission identity:
`Capstone_Project__Demo_.pdf` is another student's October 2025 graduation
project; the print reference is a different student's project and council.
Therefore the active cover/footer fields were left unchanged, pending decision:

- Cover: “BÁO CÁO / ĐỒ ÁN MÔN HỌC KỸ THUẬT MÁY TÍNH”.
- Topic: “Hiện thực bộ tăng tốc CNN dựa trên RISC-V”.
- Date: “TP. HỒ CHÍ MINH, THÁNG 12/2025”.
- Running footer: “Đồ án môn học Kỹ thuật Máy tính - CO4041”.
- “HỘI ĐỒNG:” is empty. Confirm whether this field applies and its exact value.

Confirm the official category/degree wording, topic if required, date and council;
update cover/footer consistently. The current date was not used as a submission date.

### Final build and visual audit

- Command, from `thesis_report/`:
  `latexmk -pdf -gg -interaction=nonstopmode -halt-on-error main.tex` — passed.
- `git diff --check` — passed after documentation and evidence updates.
- `pdfinfo main.pdf`: **53 A4 pages**. Cover = PDF page 1; roman front matter
  = i–viii (PDF pages 2–9); numbered main matter = 1–44 (PDF pages 10–53).
- Abstract: PDF page 4 (iii). Declaration pending page: PDF page 2 (i).
  TOC: PDF pages 5–7. List of figures: PDF page 8. List of tables: PDF page 9.
  Bibliography: printed page 44 / PDF page 53, linked in TOC.
- Current figure locations (printed / one-based PDF): 4.1 = 25/34;
  4.2 = 26/35; 4.3 = 30/39; 4.4 = 32/41; 5.1 = 39/48.
- Chapter 5 conclusion: section 5.12, printed pages 42–43 / PDF pages 51–52.
- Source/auxiliary audit: no duplicate labels; every reference resolves;
  no unresolved citations; bibliography keys exactly match cited keys.
  Final log: zero overfull boxes, duplicate PDF destinations or BibTeX warnings.
- Remaining log notices: vntex default UTF-8 input encoding, obsolete PGF snakes
  library, four geometry over-specification warnings (horizontal/vertical twice),
  and five underfull hboxes in existing Chapter 2 material. No float-placement
  warning remains. Template settings were not redesigned to silence these notices.
- Rendered with `pdftoppm` and visually inspected: cover, prepared declaration,
  abstract, all TOC pages, both lists, Chapter 1 opening, all four Chapter 4
  figures, Figure 5.1, Chapter 5 ending and bibliography. No clipping, caption
  overlap or unreadable figure/table content was observed at review scale.
- Only thesis documentation changed. Chapters 2–3 and all technical source,
  models, datasets, binaries, evaluation scripts and FPGA results are untouched.
  No firmware/RTL/native builds or new simulations were needed or run.
- Not submission-ready while declaration and official identity are unresolved.
  Original host/matched/historical raw evidence archival remains a reproducibility
  limitation; physical TinyMobileNet board validation remains pending as stated.
  No commit made.
