# TinyMobileNet thesis vector figures

These five TikZ sources are included directly by Chapters 4–5 at 0.93 text
width. `styles.tex` defines local grayscale block, HW, SW, RAM and arrow
styles. No additional packages or external image conversion are required.

Build from `thesis_report/`:

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
```

## Source evidence and abstraction

All technical sources below are in `RISCVAIoT/MyTinyMobileNetSoC/`.

- `network.tex` (4.1): dimensions and call order in `main_tinymobilenet.c`;
  dispatch and arithmetic in `dl_ops.c`, including `DWStride2CPU`, the
  exact DW2 branch, `GlobalAveragePool_TFLM`, and `FullyConnected2D_TFLM`.
  GAP and FC both call `MultiplyByQuantizedMultiplier`, whose SoC path
  writes the separate Quant accelerator. The DW2 inset labels output
  window origins inside a loaded patch, rather than individual input values.
- `soc.tex` (4.2): RAM size, decode, peripheral instances, ready gating,
  and CPU parameters in `my_soc.v`; CPU-mediated operand programming in
  `dl_ops.c`. The standalone multiplier is included because it exists in
  the SoC, with its unused inference status stated explicitly. Arrows
  summarize register transactions; they are not a separate bus protocol.
- `pointwise.tex` (4.3): `my_pw_conv_accel.v` storage, shared products /
  reduction tree, sequential `batch_bank` updates, cache row selection,
  and `rvalid` gating. A datapath here means the complete dot-product
  multiplier-lane array and reduction tree, shared across output channels;
  it does not mean one scalar multiplier. Cache preload lifetime is from
  `CachedPW1Hardware` in `dl_ops.c`: once per invocation, reused over 784
  spatial positions, preloaded again on each image. The timeline counts
  four compute edges after acceptance of the trigger, not bus latency.
- `firmware.tex` (4.4): `start.s`, `main_tinymobilenet.c`, `dl_ops.c`.
  Input preparation summarizes embedded-image selection and validation;
  it does not imply a copy into `buf_a` before Conv0. Quant is a separate
  synchronous MMIO operation for every layer, including GAP and FC.
  START precedes the Conv0 UART message; STOP follows the FC cycle-count
  message and precedes argmax, score/label output and LED update.
- `tile-reuse.tex` (5.1): `TileConv0Hardware` and the retained generic
  channel-first Conv path in `dl_ops.c`; traffic also tabulated in the
  walkthrough, section on Level 6. The loop panels illustrate reuse scope,
  not instruction-by-instruction ordering: the retained generic helper
  writes the kernel before the patch. Bias / offset / clamp are abstracted
  into per-output processing; the figure does not propose a new algorithm.

Conv0 traffic can also be checked from the loop bounds: 10 x 10 tiles,
25 patch writes per tile, 16 output channels. There are 2,116 valid source
positions summed across all patches. Thus input writes are 2,500 vs
40,000, valid input RAM loads 2,116 vs 33,856, and result reads
28 x 28 x 16 = 12,544 vs 100 x 9 x 16 = 14,400. Each valid output makes
five Quant transactions, giving 62,720 in both schedules; stores remain
12,544. No historical instruction-count comparison is used.

Existing figure labels (including their `-placeholder` suffixes) are
preserved to maintain references. Captions are Vietnamese; diagram labels
are concise English. Figure sources and technical code are unchanged in the final correction pass.
Chapter 1 ownership wording was clarified separately.

## Current final validation — 2026-10-15

- From `thesis_report/`, `latexmk -pdf -gg -interaction=nonstopmode
  -halt-on-error main.tex` passed. `git diff --check` passed.
- Current PDF: **53 A4 pages**; roman front matter i–viii plus cover,
  main matter 1–44. Earlier pagination records have been removed.
- Figure locations:

  | Figure | Printed page | PDF page (one-based) |
  |---|---:|---:|
  | 4.1 network | 25 | 34 |
  | 4.2 SoC | 26 | 35 |
  | 4.3 Pointwise | 30 | 39 |
  | 4.4 firmware | 32 | 41 |
  | 5.1 Conv0 reuse | 39 | 48 |

- All five pages were rendered with `pdftoppm` and visually inspected for
  clipping, overlap, readable labels and caption placement. All five figures
  have explicit body callouts; their labels and artwork are unchanged.
- The final log has no overfull boxes, unresolved references/citations,
  duplicate labels, duplicate PDF destinations or BibTeX warnings.
  Remaining notices: vntex default input encoding, obsolete PGF snakes,
  geometry over-specification and five earlier Chapter 2 underfull hboxes.
- List of figures is PDF page 8; list of tables is PDF page 9.
  See `../../evidence.md` for the full build audit and pending declaration/
  cover identity decisions. These prevent final submission readiness.
- No RTL/firmware/native builds or simulations were run in this documentation
  pass. Numerical results and technical source were preserved. No commit made.
