# Versioned Gen 2B model references

Active: **gen2b-cifar10-a59-int8-v1**, selected epoch 59 of Experiment A.
The active.json pointer pins the immutable version manifest. Every artifact,
including verifier/kernel sources and golden vectors, is covered by it.
See the version's CONTRACT.md and ../../docs/Gen2B_Model_Reference_Promotion.md.

Version contents must never change. Future model, quantization, vector or
verifier changes require a new ID and manifest; update active.json separately.
Hashes provide consistency checks, not a signature or filesystem immutability.
.gitattributes disables text conversion and filters for byte-exact Git storage.

All 10000 test inputs, labels and 500 calibration samples are included. The
full bundle is about 33.3 MiB, with every artifact below 3 MiB. It uses ordinary
Git files: no LFS, ignored dataset cache, external download, or retraining is
required for recovery or native verification. Existing generated/experiments
remain separate historical artifacts. New files must be included in the
reviewed commit before a fresh checkout of that commit can contain them;
this task intentionally makes no commit.

From MyTinyMobileNetGen2/:

```bash
python3 -B scripts/hardware_reference.py verify
python3 -B scripts/hardware_reference.py verify --mode native --limit 100 --output /tmp/ref-native100
python3 -B scripts/hardware_reference.py verify --mode native --limit 10000 --output /tmp/ref-native10000
.venv/bin/python -B scripts/hardware_reference.py verify --mode both --limit 10000 --reexport --output /tmp/ref-both10000
python3 -B scripts/hardware_reference.py recover --destination /tmp/recovered-reference
python3 -B scripts/test_reference_integrity.py
```

Use fresh output names. Native recovery needs Python 3.11+ and C11 cc only;
TFLite comparison additionally needs the frozen version's requirements.txt.
The Keras/TFLite bytes themselves are preserved; converter output byte identity
across environments is not assumed. --reexport reproduces JSON/C arrays
byte-for-byte from the frozen TFLite with the recorded dependencies.
