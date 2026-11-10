# Gen 2 RGB / DMA Plan

## 1. Gen 1 baseline

Frozen tag: `gen1-final`. Current reference sources: `../../MyTinyMobileNetSoC/`.

## 2. Gen 1 limitations

MNIST baseline; CPU orchestrates MMIO transfers. Accelerators have no DMA interface.

## 3. Gen 2 objectives

Establish RGB CIFAR-10 support first; investigate local buffers and DMA afterward.

## 4. RGB/CIFAR-10 workload

Plan for 32×32 RGB input and ten classes; preprocessing and quantization remain to be specified.

## 5. proposed network topology

To be selected and validated; no layer sizes or accuracy targets are fixed yet.

## 6. multi-channel Conv0 requirements

Plan accumulation across three input channels; review layout, offsets, accumulator width, and per-channel scaling.

## 7. memory architecture

Inventory code, weights, activations, and scratch space before choosing a memory map.

## 8. software migration

Review Gen 1 startup, operators, quantization, and reference checks as future reuse candidates.

## 9. RTL migration

Review CPU, UART, accelerator interfaces, and board flows; copy selected components only when needed.

## 10. verification strategy

Establish an independent RGB software reference, signed arithmetic checks, focused RTL tests, and score/prediction comparisons.

## 11. future DMA/local-buffer stage

Plan only after the RGB baseline is validated; interfaces and ownership remain open.

## 12. non-goals

No YOLO, camera, PetaLinux, INT4, large PE array, compiler/runtime framework, or full DMA implementation now.

## 13. open questions

Choose topology, preprocessing, quantization reference, memory budget, reuse boundaries, and later transfer interfaces.
