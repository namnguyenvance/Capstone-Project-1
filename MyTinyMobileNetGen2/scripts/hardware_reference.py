#!/usr/bin/env python3
"""Check/recover the pinned reference using only Git-deliverable files."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
sys.dont_write_bytecode=True

def main():
    p=argparse.ArgumentParser()
    p.add_argument('command',choices=['verify','recover'])
    p.add_argument('--reference-root',type=Path,default=Path(__file__).resolve().parents[1]/'model/references')
    p.add_argument('--destination',type=Path);p.add_argument('--mode',choices=['integrity','native','both'],default='integrity')
    p.add_argument('--limit',type=int,choices=[100,10000],default=100);p.add_argument('--output',type=Path)
    p.add_argument('--reexport',action='store_true');a=p.parse_args()
    root=a.reference_root.resolve();active=json.loads((root/'active.json').read_text());version=active['version_id']
    if Path(version).name!=version:raise ValueError('Unsafe version')
    bundle=root/version;manifest=bundle/'manifest.json'
    if hashlib.sha256(manifest.read_bytes()).hexdigest()!=active['manifest_sha256']:raise ValueError('Pinned manifest mismatch')
    def invoke(b,mode):
        command=[sys.executable,'-B',str(b/'tools/reference_engine.py'),'--bundle',str(b),
                 '--manifest-sha',active['manifest_sha256'],'--mode',mode,'--limit',str(a.limit)]
        if a.output:command+=['--output',str(a.output)]
        if a.reexport:command+=['--reexport']
        subprocess.run(command,check=True)
    invoke(bundle,'integrity')
    if a.command=='recover':
        if not a.destination:p.error('--destination required')
        dest=a.destination.resolve();dest.mkdir(parents=True,exist_ok=False)
        shutil.copyfile(root/'active.json',dest/'active.json')
        shutil.copytree(bundle,dest/version)
        invoke(dest/version,'integrity')
        print('Recovered self-contained bundle:',dest/version)
    else:invoke(bundle,a.mode)
if __name__=='__main__':main()
