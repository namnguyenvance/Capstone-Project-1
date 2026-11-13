#!/usr/bin/env python3
"""Meaningful failure-path checks using only the release deliverables."""
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]/'model/references'
ACTIVE=json.loads((ROOT/'active.json').read_text())
SOURCE=ROOT/ACTIVE['version_id']
spec=importlib.util.spec_from_file_location('frozen_engine',SOURCE/'tools/reference_engine.py')
engine=importlib.util.module_from_spec(spec);spec.loader.exec_module(engine)

class IntegrityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory(prefix='gen2b-integrity-')
        cls.bundle=Path(cls.temp.name)/'bundle';shutil.copytree(SOURCE,cls.bundle)
    @classmethod
    def tearDownClass(cls):cls.temp.cleanup()
    def check(self):return engine.integrity(self.bundle,ACTIVE['manifest_sha256'])
    def test_valid_bundle(self):self.assertEqual(self.check()['version_id'],ACTIVE['version_id'])
    def test_wrong_manifest_pin(self):
        with self.assertRaisesRegex(ValueError,'pinned SHA-256'):engine.integrity(self.bundle,'0'*64)
    def test_corrupt_export(self):
        p=self.bundle/'model/export.json';original=p.read_bytes()
        try:
            p.write_bytes(original+b' ')
            with self.assertRaisesRegex(ValueError,'integrity failure'):self.check()
        finally:p.write_bytes(original)
    def test_missing_vector(self):
        p=self.bundle/'vectors/layer00.first100.chw.i8.gz';backup=p.with_suffix('.saved');p.rename(backup)
        try:
            with self.assertRaises(FileNotFoundError):self.check()
        finally:backup.rename(p)
    def test_unlisted_file(self):
        p=self.bundle/'unlisted.txt';p.write_text('unexpected')
        try:
            with self.assertRaisesRegex(ValueError,'Unexpected version files'):self.check()
        finally:p.unlink()
if __name__=='__main__':unittest.main()
