#!/usr/bin/env python3
"""Dependency-free independent Python integer oracle versus native C stages."""
import ctypes as C
import json
import pathlib
import subprocess
import unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]
BUILD = ROOT / 'build'

def requant(x, m, s):
    if s < 0:
        x = max(-2**31, min(2**31-1, x * 2**(-s)))
    p = x*m
    n = 2**30 if p >= 0 else 1-2**30
    y = (abs(p+n)//2**31) * (-1 if p+n < 0 else 1)
    if s > 0:
        y = ((abs(y)+2**(s-1))//2**s)*(-1 if y < 0 else 1)
    return y

def build():
    BUILD.mkdir(exist_ok=True)
    subprocess.run(['cc','-std=c11','-O2','-Wall','-Wextra','-Wconversion',
                    '-Werror','-fPIC','-shared',str(pathlib.Path(__file__).with_name('kernels.c')),
                    '-o',str(BUILD/'libg2.so')],check=True)
    return C.CDLL(str(BUILD/'libg2.so'))

def arr(t, values):
    return (t*len(values))(*values)

class RGBTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lib=build()
    def test_requant_edges(self):
        f=self.lib.g2_requant
        f.restype=C.c_int32
        for x in [-2**31,-2147483647,-65537,-3,-2,-1,0,1,2,3,65537,2**31-1]:
            for m in [0,1,2**30,2**31-1]:
                for s in [-30,-2,0,1,7,31]:
                    self.assertEqual(f(x,m,s),requant(x,m,s))
    def test_rgb(self):
        x=[((i*37+13)%256)-128 for i in range(48)]
        w=[((i*19+7)%255)-127 for i in range(54)]
        x[:2]=[-128,127]; w[:2]=[-128,127]
        bias=[1234,-4321]; mult=[2**30,1610612736]; shifts=[5,5]
        count=0
        for stride in [1,2]:
            oh=(4+stride-1)//stride
            pad=max(0,(oh-1)*stride+3-4)//2
            n=2*oh*oh
            out=(C.c_int8*n)(); traces=[(C.c_int32*n)() for _ in range(3)]
            self.lib.g2_conv(arr(C.c_int8,x),arr(C.c_int8,w),arr(C.c_int32,bias),
                4,4,3,2,3,3,stride,pad,pad,oh,oh,-11,5,
                arr(C.c_int32,mult),arr(C.c_int32,shifts),-128,127,0,out,*traces)
            expected=[[],[],[],[]]
            for o in range(2):
                for y in range(oh):
                    for z in range(oh):
                        a=0
                        for ky in range(3):
                            for kx in range(3):
                                iy=y*stride+ky-pad; ix=z*stride+kx-pad
                                if 0<=iy<4 and 0<=ix<4:
                                    # Pixel-first loop order intentionally differs from C.
                                    for c in range(3):
                                        a+=(x[c*16+iy*4+ix]+11)*w[o*27+c*9+ky*3+kx]
                        b=a+bias[o]; q=requant(b,mult[o],shifts[o])
                        for values,value in zip(expected,[a,b,q,max(-128,min(127,q+5))]):
                            values.append(value)
            for actual,ref in zip([*traces,out],expected):
                self.assertEqual(list(actual),ref)
            self.assertIn(-128,expected[3]); self.assertIn(127,expected[3])
            count+=n
        print(json.dumps({'rgb_outputs_compared':count,'stages_per_output':4}))
    def test_depthwise(self):
        # Three distinct channels ensure no accidental cross-channel sum.
        x=[((i*43)%256)-128 for i in range(48)]
        w=[((i*17)%255)-127 for i in range(27)]
        bias=[-99,0,101]; m=[2**30]*3; shift=[4,5,6]
        out=(C.c_int8*12)()
        self.lib.g2_conv(arr(C.c_int8,x),arr(C.c_int8,w),arr(C.c_int32,bias),
            4,4,3,3,3,3,2,0,0,2,2,7,-5,arr(C.c_int32,m),arr(C.c_int32,shift),-5,100,1,out,None,None,None)
        expected=[]
        for c in range(3):
            for y in range(2):
                for z in range(2):
                    acc=bias[c]
                    for ky in range(3):
                        for kx in range(3):
                            iy=2*y+ky; ix=2*z+kx
                            if iy<4 and ix<4:
                                acc+=(x[c*16+iy*4+ix]-7)*w[c*9+ky*3+kx]
                    expected.append(max(-5,min(100,requant(acc,m[c],shift[c])-5)))
        self.assertEqual(list(out),expected)
    def test_layout_and_multiplier(self):
        import sys
        sys.path.insert(0,str(ROOT/'model/quantization'))
        from export import multiplier
        # HWC RGB pixel triples, explicitly converted into separate CHW planes.
        hwc=[(y*4+z)*3+c for y in range(4) for z in range(4) for c in range(3)]
        chw=[hwc[(y*4+z)*3+c] for c in range(3) for y in range(4) for z in range(4)]
        self.assertEqual(chw[:16],list(range(0,48,3)))
        self.assertEqual(chw[16:32],list(range(1,48,3)))
        for real in [0.125,0.5,0.99999999999,1.,2.,17.3]:
            m,s=multiplier(real)
            self.assertLessEqual(abs(m/2**31*2**(-s)-real),real*1e-9)
        for invalid in [0,-1,float('inf'),float('nan'),2.**40,2.**-50]:
            with self.assertRaises(ValueError): multiplier(invalid)
    def test_mean_fc(self):
        x=[-128,-1,0,127,1,2,3,4]; out=(C.c_int8*2)()
        self.lib.g2_mean(arr(C.c_int8,x),4,2,-3,5,2**30,1,out)
        self.assertEqual(list(out),[max(-128,min(127,requant(sum(x[c*4:c*4+4])+12,2**30,1)+5)) for c in range(2)])
        w=[-128,127,3,-7]; b=[100,-90]; m=[2**30]*2; s=[8]*2
        self.lib.g2_fc(arr(C.c_int8,[-128,127]),arr(C.c_int8,w),arr(C.c_int32,b),2,2,-11,3,arr(C.c_int32,m),arr(C.c_int32,s),out)
        self.assertEqual(list(out),[max(-128,min(127,requant(b[o]+(-128+11)*w[o*2]+(127+11)*w[o*2+1],m[o],s[o])+3)) for o in range(2)])

if __name__=='__main__':
    unittest.main()
