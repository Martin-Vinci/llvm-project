; RUN: llc -aarch64-sve-vector-bits-min=128  < %s | FileCheck %s -check-prefix=NO_SVE
; RUN: llc -aarch64-sve-vector-bits-min=256  < %s | FileCheck %s -check-prefixes=CHECK,VBITS_EQ_256
; RUN: llc -aarch64-sve-vector-bits-min=384  < %s | FileCheck %s -check-prefixes=CHECK
; RUN: llc -aarch64-sve-vector-bits-min=512  < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512
; RUN: llc -aarch64-sve-vector-bits-min=640  < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512
; RUN: llc -aarch64-sve-vector-bits-min=768  < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512
; RUN: llc -aarch64-sve-vector-bits-min=896  < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512
; RUN: llc -aarch64-sve-vector-bits-min=1024 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512,VBITS_GE_1024
; RUN: llc -aarch64-sve-vector-bits-min=1152 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512,VBITS_GE_1024
; RUN: llc -aarch64-sve-vector-bits-min=1280 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512,VBITS_GE_1024
; RUN: llc -aarch64-sve-vector-bits-min=1408 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512,VBITS_GE_1024
; RUN: llc -aarch64-sve-vector-bits-min=1536 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512,VBITS_GE_1024
; RUN: llc -aarch64-sve-vector-bits-min=1664 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512,VBITS_GE_1024
; RUN: llc -aarch64-sve-vector-bits-min=1792 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512,VBITS_GE_1024
; RUN: llc -aarch64-sve-vector-bits-min=1920 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512,VBITS_GE_1024
; RUN: llc -aarch64-sve-vector-bits-min=2048 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512,VBITS_GE_1024,VBITS_GE_2048

target triple = "aarch64-unknown-linux-gnu"

; Don't use SVE when its registers are no bigger than NEON.
; NO_SVE-NOT: ptrue

;
; LD1B
;

define void @masked_gather_v2i8(<2 x i8>* %a, <2 x i8*>* %b) #0 {
; CHECK-LABEL: masked_gather_v2i8:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldrb w8, [x0]
; CHECK-NEXT:    ldrb w9, [x0, #1]
; CHECK-NEXT:    ldr q0, [x1]
; CHECK-NEXT:    ptrue p0.d, vl2
; CHECK-NEXT:    fmov s1, w8
; CHECK-NEXT:    mov v1.s[1], w9
; CHECK-NEXT:    cmeq v1.2s, v1.2s, #0
; CHECK-NEXT:    ushll v1.2d, v1.2s, #0
; CHECK-NEXT:    cmpne p0.d, p0/z, z1.d, #0
; CHECK-NEXT:    ld1sb { z0.d }, p0/z, [z0.d]
; CHECK-NEXT:    ptrue p0.s, vl2
; CHECK-NEXT:    xtn v0.2s, v0.2d
; CHECK-NEXT:    st1b { z0.s }, p0, [x0]
; CHECK-NEXT:    ret
  %cval = load <2 x i8>, <2 x i8>* %a
  %ptrs = load <2 x i8*>, <2 x i8*>* %b
  %mask = icmp eq <2 x i8> %cval, zeroinitializer
  %vals = call <2 x i8> @llvm.masked.gather.v2i8(<2 x i8*> %ptrs, i32 8, <2 x i1> %mask, <2 x i8> undef)
  store <2 x i8> %vals, <2 x i8>* %a
  ret void
}

define void @masked_gather_v4i8(<4 x i8>* %a, <4 x i8*>* %b) #0 {
; CHECK-LABEL: masked_gather_v4i8:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr s0, [x0]
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    ld1d { z1.d }, p0/z, [x1]
; CHECK-NEXT:    ushll v0.8h, v0.8b, #0
; CHECK-NEXT:    cmeq v0.4h, v0.4h, #0
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1sb { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    ptrue p0.h, vl4
; CHECK-NEXT:    uzp1 z0.s, z0.s, z0.s
; CHECK-NEXT:    uzp1 z0.h, z0.h, z0.h
; CHECK-NEXT:    st1b { z0.h }, p0, [x0]
; CHECK-NEXT:    ret
  %cval = load <4 x i8>, <4 x i8>* %a
  %ptrs = load <4 x i8*>, <4 x i8*>* %b
  %mask = icmp eq <4 x i8> %cval, zeroinitializer
  %vals = call <4 x i8> @llvm.masked.gather.v4i8(<4 x i8*> %ptrs, i32 8, <4 x i1> %mask, <4 x i8> undef)
  store <4 x i8> %vals, <4 x i8>* %a
  ret void
}

define void @masked_gather_v8i8(<8 x i8>* %a, <8 x i8*>* %b) #0 {
; Ensure sensible type legalisation.
; VBITS_EQ_256-LABEL: masked_gather_v8i8:
; VBITS_EQ_256:       // %bb.0:
; VBITS_EQ_256-NEXT:    ldr d0, [x0]
; VBITS_EQ_256-NEXT:    mov x8, #4
; VBITS_EQ_256-NEXT:    ptrue p0.d, vl4
; VBITS_EQ_256-NEXT:    ld1d { z1.d }, p0/z, [x1, x8, lsl #3]
; VBITS_EQ_256-NEXT:    cmeq v0.8b, v0.8b, #0
; VBITS_EQ_256-NEXT:    zip2 v3.8b, v0.8b, v0.8b
; VBITS_EQ_256-NEXT:    zip1 v0.8b, v0.8b, v0.8b
; VBITS_EQ_256-NEXT:    shl v3.4h, v3.4h, #8
; VBITS_EQ_256-NEXT:    shl v0.4h, v0.4h, #8
; VBITS_EQ_256-NEXT:    ld1d { z2.d }, p0/z, [x1]
; VBITS_EQ_256-NEXT:    sshr v3.4h, v3.4h, #8
; VBITS_EQ_256-NEXT:    sshr v0.4h, v0.4h, #8
; VBITS_EQ_256-NEXT:    uunpklo z3.s, z3.h
; VBITS_EQ_256-NEXT:    uunpklo z0.s, z0.h
; VBITS_EQ_256-NEXT:    uunpklo z3.d, z3.s
; VBITS_EQ_256-NEXT:    uunpklo z0.d, z0.s
; VBITS_EQ_256-NEXT:    cmpne p1.d, p0/z, z3.d, #0
; VBITS_EQ_256-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; VBITS_EQ_256-NEXT:    ld1sb { z0.d }, p1/z, [z1.d]
; VBITS_EQ_256-NEXT:    ld1sb { z1.d }, p0/z, [z2.d]
; VBITS_EQ_256-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_EQ_256-NEXT:    uzp1 z1.s, z1.s, z1.s
; VBITS_EQ_256-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_EQ_256-NEXT:    uzp1 z1.h, z1.h, z1.h
; VBITS_EQ_256-NEXT:    uzp1 v0.8b, v1.8b, v0.8b
; VBITS_EQ_256-NEXT:    str d0, [x0]
; VBITS_EQ_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: masked_gather_v8i8:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ldr d0, [x0]
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_512-NEXT:    cmeq v0.8b, v0.8b, #0
; VBITS_GE_512-NEXT:    uunpklo z0.h, z0.b
; VBITS_GE_512-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; VBITS_GE_512-NEXT:    ld1b { z0.d }, p0/z, [z1.d]
; VBITS_GE_512-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_512-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_512-NEXT:    uzp1 z0.b, z0.b, z0.b
; VBITS_GE_512-NEXT:    str d0, [x0]
; VBITS_GE_512-NEXT:    ret
  %cval = load <8 x i8>, <8 x i8>* %a
  %ptrs = load <8 x i8*>, <8 x i8*>* %b
  %mask = icmp eq <8 x i8> %cval, zeroinitializer
  %vals = call <8 x i8> @llvm.masked.gather.v8i8(<8 x i8*> %ptrs, i32 8, <8 x i1> %mask, <8 x i8> undef)
  store <8 x i8> %vals, <8 x i8>* %a
  ret void
}

define void @masked_gather_v16i8(<16 x i8>* %a, <16 x i8*>* %b) #0 {
; VBITS_GE_1024-LABEL: masked_gather_v16i8:
; VBITS_GE_1024:       // %bb.0:
; VBITS_GE_1024-NEXT:    ldr q0, [x0]
; VBITS_GE_1024-NEXT:    ptrue p0.d, vl16
; VBITS_GE_1024-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_1024-NEXT:    cmeq v0.16b, v0.16b, #0
; VBITS_GE_1024-NEXT:    uunpklo z0.h, z0.b
; VBITS_GE_1024-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_1024-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_1024-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; VBITS_GE_1024-NEXT:    ld1b { z0.d }, p0/z, [z1.d]
; VBITS_GE_1024-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_1024-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_1024-NEXT:    uzp1 z0.b, z0.b, z0.b
; VBITS_GE_1024-NEXT:    str q0, [x0]
; VBITS_GE_1024-NEXT:    ret
  %cval = load <16 x i8>, <16 x i8>* %a
  %ptrs = load <16 x i8*>, <16 x i8*>* %b
  %mask = icmp eq <16 x i8> %cval, zeroinitializer
  %vals = call <16 x i8> @llvm.masked.gather.v16i8(<16 x i8*> %ptrs, i32 8, <16 x i1> %mask, <16 x i8> undef)
  store <16 x i8> %vals, <16 x i8>* %a
  ret void
}

define void @masked_gather_v32i8(<32 x i8>* %a, <32 x i8*>* %b) #0 {
; VBITS_GE_2048-LABEL: masked_gather_v32i8:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.b, vl32
; VBITS_GE_2048-NEXT:    ld1b { z0.b }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    cmpeq p2.b, p0/z, z0.b, #0
; VBITS_GE_2048-NEXT:    mov z0.b, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.h, z0.b
; VBITS_GE_2048-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1b { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_2048-NEXT:    uzp1 z0.b, z0.b, z0.b
; VBITS_GE_2048-NEXT:    st1b { z0.b }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cval = load <32 x i8>, <32 x i8>* %a
  %ptrs = load <32 x i8*>, <32 x i8*>* %b
  %mask = icmp eq <32 x i8> %cval, zeroinitializer
  %vals = call <32 x i8> @llvm.masked.gather.v32i8(<32 x i8*> %ptrs, i32 8, <32 x i1> %mask, <32 x i8> undef)
  store <32 x i8> %vals, <32 x i8>* %a
  ret void
}

;
; LD1H
;

define void @masked_gather_v2i16(<2 x i16>* %a, <2 x i16*>* %b) #0 {
; CHECK-LABEL: masked_gather_v2i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldrh w8, [x0]
; CHECK-NEXT:    ldrh w9, [x0, #2]
; CHECK-NEXT:    ldr q0, [x1]
; CHECK-NEXT:    ptrue p0.d, vl2
; CHECK-NEXT:    fmov s1, w8
; CHECK-NEXT:    mov v1.s[1], w9
; CHECK-NEXT:    cmeq v1.2s, v1.2s, #0
; CHECK-NEXT:    ushll v1.2d, v1.2s, #0
; CHECK-NEXT:    cmpne p0.d, p0/z, z1.d, #0
; CHECK-NEXT:    ld1sh { z0.d }, p0/z, [z0.d]
; CHECK-NEXT:    ptrue p0.s, vl2
; CHECK-NEXT:    xtn v0.2s, v0.2d
; CHECK-NEXT:    st1h { z0.s }, p0, [x0]
; CHECK-NEXT:    ret
  %cval = load <2 x i16>, <2 x i16>* %a
  %ptrs = load <2 x i16*>, <2 x i16*>* %b
  %mask = icmp eq <2 x i16> %cval, zeroinitializer
  %vals = call <2 x i16> @llvm.masked.gather.v2i16(<2 x i16*> %ptrs, i32 8, <2 x i1> %mask, <2 x i16> undef)
  store <2 x i16> %vals, <2 x i16>* %a
  ret void
}

define void @masked_gather_v4i16(<4 x i16>* %a, <4 x i16*>* %b) #0 {
; CHECK-LABEL: masked_gather_v4i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr d0, [x0]
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    ld1d { z1.d }, p0/z, [x1]
; CHECK-NEXT:    cmeq v0.4h, v0.4h, #0
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1h { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    uzp1 z0.s, z0.s, z0.s
; CHECK-NEXT:    uzp1 z0.h, z0.h, z0.h
; CHECK-NEXT:    str d0, [x0]
; CHECK-NEXT:    ret
  %cval = load <4 x i16>, <4 x i16>* %a
  %ptrs = load <4 x i16*>, <4 x i16*>* %b
  %mask = icmp eq <4 x i16> %cval, zeroinitializer
  %vals = call <4 x i16> @llvm.masked.gather.v4i16(<4 x i16*> %ptrs, i32 8, <4 x i1> %mask, <4 x i16> undef)
  store <4 x i16> %vals, <4 x i16>* %a
  ret void
}

define void @masked_gather_v8i16(<8 x i16>* %a, <8 x i16*>* %b) #0 {
; Ensure sensible type legalisation.
; VBITS_EQ_256-LABEL: masked_gather_v8i16:
; VBITS_EQ_256:       // %bb.0:
; VBITS_EQ_256-NEXT:    ldr q0, [x0]
; VBITS_EQ_256-NEXT:    mov x8, #4
; VBITS_EQ_256-NEXT:    ptrue p0.d, vl4
; VBITS_EQ_256-NEXT:    ld1d { z1.d }, p0/z, [x1, x8, lsl #3]
; VBITS_EQ_256-NEXT:    cmeq v0.8h, v0.8h, #0
; VBITS_EQ_256-NEXT:    ld1d { z2.d }, p0/z, [x1]
; VBITS_EQ_256-NEXT:    uunpklo z3.s, z0.h
; VBITS_EQ_256-NEXT:    ext v0.16b, v0.16b, v0.16b, #8
; VBITS_EQ_256-NEXT:    uunpklo z0.s, z0.h
; VBITS_EQ_256-NEXT:    uunpklo z3.d, z3.s
; VBITS_EQ_256-NEXT:    uunpklo z0.d, z0.s
; VBITS_EQ_256-NEXT:    cmpne p1.d, p0/z, z3.d, #0
; VBITS_EQ_256-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; VBITS_EQ_256-NEXT:    ld1h { z2.d }, p1/z, [z2.d]
; VBITS_EQ_256-NEXT:    ld1h { z0.d }, p0/z, [z1.d]
; VBITS_EQ_256-NEXT:    uzp1 z1.s, z2.s, z2.s
; VBITS_EQ_256-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_EQ_256-NEXT:    uzp1 z1.h, z1.h, z1.h
; VBITS_EQ_256-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_EQ_256-NEXT:    mov v1.d[1], v0.d[0]
; VBITS_EQ_256-NEXT:    str q1, [x0]
; VBITS_EQ_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: masked_gather_v8i16:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ldr q0, [x0]
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_512-NEXT:    cmeq v0.8h, v0.8h, #0
; VBITS_GE_512-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; VBITS_GE_512-NEXT:    ld1h { z0.d }, p0/z, [z1.d]
; VBITS_GE_512-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_512-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_512-NEXT:    str q0, [x0]
; VBITS_GE_512-NEXT:    ret
  %cval = load <8 x i16>, <8 x i16>* %a
  %ptrs = load <8 x i16*>, <8 x i16*>* %b
  %mask = icmp eq <8 x i16> %cval, zeroinitializer
  %vals = call <8 x i16> @llvm.masked.gather.v8i16(<8 x i16*> %ptrs, i32 8, <8 x i1> %mask, <8 x i16> undef)
  store <8 x i16> %vals, <8 x i16>* %a
  ret void
}

define void @masked_gather_v16i16(<16 x i16>* %a, <16 x i16*>* %b) #0 {
; VBITS_GE_1024-LABEL: masked_gather_v16i16:
; VBITS_GE_1024:       // %bb.0:
; VBITS_GE_1024-NEXT:    ptrue p0.h, vl16
; VBITS_GE_1024-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_1024-NEXT:    ptrue p1.d, vl16
; VBITS_GE_1024-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_1024-NEXT:    cmpeq p2.h, p0/z, z0.h, #0
; VBITS_GE_1024-NEXT:    mov z0.h, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_1024-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_1024-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_1024-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_1024-NEXT:    ld1h { z0.d }, p1/z, [z1.d]
; VBITS_GE_1024-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_1024-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_1024-NEXT:    st1h { z0.h }, p0, [x0]
; VBITS_GE_1024-NEXT:    ret
  %cval = load <16 x i16>, <16 x i16>* %a
  %ptrs = load <16 x i16*>, <16 x i16*>* %b
  %mask = icmp eq <16 x i16> %cval, zeroinitializer
  %vals = call <16 x i16> @llvm.masked.gather.v16i16(<16 x i16*> %ptrs, i32 8, <16 x i1> %mask, <16 x i16> undef)
  store <16 x i16> %vals, <16 x i16>* %a
  ret void
}

define void @masked_gather_v32i16(<32 x i16>* %a, <32 x i16*>* %b) #0 {
; VBITS_GE_2048-LABEL: masked_gather_v32i16:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.h, vl32
; VBITS_GE_2048-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    cmpeq p2.h, p0/z, z0.h, #0
; VBITS_GE_2048-NEXT:    mov z0.h, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1h { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_2048-NEXT:    st1h { z0.h }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cval = load <32 x i16>, <32 x i16>* %a
  %ptrs = load <32 x i16*>, <32 x i16*>* %b
  %mask = icmp eq <32 x i16> %cval, zeroinitializer
  %vals = call <32 x i16> @llvm.masked.gather.v32i16(<32 x i16*> %ptrs, i32 8, <32 x i1> %mask, <32 x i16> undef)
  store <32 x i16> %vals, <32 x i16>* %a
  ret void
}

;
; LD1W
;

define void @masked_gather_v2i32(<2 x i32>* %a, <2 x i32*>* %b) #0 {
; CHECK-LABEL: masked_gather_v2i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr d0, [x0]
; CHECK-NEXT:    ldr q1, [x1]
; CHECK-NEXT:    ptrue p0.d, vl2
; CHECK-NEXT:    cmeq v0.2s, v0.2s, #0
; CHECK-NEXT:    ushll v0.2d, v0.2s, #0
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1w { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    xtn v0.2s, v0.2d
; CHECK-NEXT:    str d0, [x0]
; CHECK-NEXT:    ret
  %cval = load <2 x i32>, <2 x i32>* %a
  %ptrs = load <2 x i32*>, <2 x i32*>* %b
  %mask = icmp eq <2 x i32> %cval, zeroinitializer
  %vals = call <2 x i32> @llvm.masked.gather.v2i32(<2 x i32*> %ptrs, i32 8, <2 x i1> %mask, <2 x i32> undef)
  store <2 x i32> %vals, <2 x i32>* %a
  ret void
}

define void @masked_gather_v4i32(<4 x i32>* %a, <4 x i32*>* %b) #0 {
; CHECK-LABEL: masked_gather_v4i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr q0, [x0]
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    ld1d { z1.d }, p0/z, [x1]
; CHECK-NEXT:    cmeq v0.4s, v0.4s, #0
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1w { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    uzp1 z0.s, z0.s, z0.s
; CHECK-NEXT:    str q0, [x0]
; CHECK-NEXT:    ret
  %cval = load <4 x i32>, <4 x i32>* %a
  %ptrs = load <4 x i32*>, <4 x i32*>* %b
  %mask = icmp eq <4 x i32> %cval, zeroinitializer
  %vals = call <4 x i32> @llvm.masked.gather.v4i32(<4 x i32*> %ptrs, i32 8, <4 x i1> %mask, <4 x i32> undef)
  store <4 x i32> %vals, <4 x i32>* %a
  ret void
}

define void @masked_gather_v8i32(<8 x i32>* %a, <8 x i32*>* %b) #0 {
; Ensure sensible type legalisation.
; VBITS_EQ_256-LABEL: masked_gather_v8i32:
; VBITS_EQ_256:       // %bb.0:
; VBITS_EQ_256-NEXT:    stp x29, x30, [sp, #-16]! // 16-byte Folded Spill
; VBITS_EQ_256-NEXT:    sub x9, sp, #48
; VBITS_EQ_256-NEXT:    mov x29, sp
; VBITS_EQ_256-NEXT:    and sp, x9, #0xffffffffffffffe0
; VBITS_EQ_256-NEXT:    .cfi_def_cfa w29, 16
; VBITS_EQ_256-NEXT:    .cfi_offset w30, -8
; VBITS_EQ_256-NEXT:    .cfi_offset w29, -16
; VBITS_EQ_256-NEXT:    ptrue p0.s, vl8
; VBITS_EQ_256-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_EQ_256-NEXT:    mov x8, #4
; VBITS_EQ_256-NEXT:    ptrue p1.d, vl4
; VBITS_EQ_256-NEXT:    ld1d { z1.d }, p1/z, [x1, x8, lsl #3]
; VBITS_EQ_256-NEXT:    cmpeq p2.s, p0/z, z0.s, #0
; VBITS_EQ_256-NEXT:    mov x8, sp
; VBITS_EQ_256-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_EQ_256-NEXT:    ld1d { z2.d }, p1/z, [x1]
; VBITS_EQ_256-NEXT:    st1w { z0.s }, p0, [x8]
; VBITS_EQ_256-NEXT:    ldr q0, [sp, #16]
; VBITS_EQ_256-NEXT:    uunpklo z0.d, z0.s
; VBITS_EQ_256-NEXT:    cmpne p2.d, p1/z, z0.d, #0
; VBITS_EQ_256-NEXT:    ld1w { z0.d }, p2/z, [z1.d]
; VBITS_EQ_256-NEXT:    ldr q1, [sp]
; VBITS_EQ_256-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_EQ_256-NEXT:    uunpklo z1.d, z1.s
; VBITS_EQ_256-NEXT:    cmpne p1.d, p1/z, z1.d, #0
; VBITS_EQ_256-NEXT:    ld1w { z1.d }, p1/z, [z2.d]
; VBITS_EQ_256-NEXT:    ptrue p1.s, vl4
; VBITS_EQ_256-NEXT:    uzp1 z1.s, z1.s, z1.s
; VBITS_EQ_256-NEXT:    splice z1.s, p1, z1.s, z0.s
; VBITS_EQ_256-NEXT:    st1w { z1.s }, p0, [x0]
; VBITS_EQ_256-NEXT:    mov sp, x29
; VBITS_EQ_256-NEXT:    ldp x29, x30, [sp], #16 // 16-byte Folded Reload
; VBITS_EQ_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: masked_gather_v8i32:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.s, vl8
; VBITS_GE_512-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ptrue p1.d, vl8
; VBITS_GE_512-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_512-NEXT:    cmpeq p2.s, p0/z, z0.s, #0
; VBITS_GE_512-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_512-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_512-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_512-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_512-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_512-NEXT:    ret
  %cval = load <8 x i32>, <8 x i32>* %a
  %ptrs = load <8 x i32*>, <8 x i32*>* %b
  %mask = icmp eq <8 x i32> %cval, zeroinitializer
  %vals = call <8 x i32> @llvm.masked.gather.v8i32(<8 x i32*> %ptrs, i32 8, <8 x i1> %mask, <8 x i32> undef)
  store <8 x i32> %vals, <8 x i32>* %a
  ret void
}

define void @masked_gather_v16i32(<16 x i32>* %a, <16 x i32*>* %b) #0 {
; VBITS_GE_1024-LABEL: masked_gather_v16i32:
; VBITS_GE_1024:       // %bb.0:
; VBITS_GE_1024-NEXT:    ptrue p0.s, vl16
; VBITS_GE_1024-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_1024-NEXT:    ptrue p1.d, vl16
; VBITS_GE_1024-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_1024-NEXT:    cmpeq p2.s, p0/z, z0.s, #0
; VBITS_GE_1024-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_1024-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_1024-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_1024-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_1024-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_1024-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_1024-NEXT:    ret
  %cval = load <16 x i32>, <16 x i32>* %a
  %ptrs = load <16 x i32*>, <16 x i32*>* %b
  %mask = icmp eq <16 x i32> %cval, zeroinitializer
  %vals = call <16 x i32> @llvm.masked.gather.v16i32(<16 x i32*> %ptrs, i32 8, <16 x i1> %mask, <16 x i32> undef)
  store <16 x i32> %vals, <16 x i32>* %a
  ret void
}

define void @masked_gather_v32i32(<32 x i32>* %a, <32 x i32*>* %b) #0 {
; VBITS_GE_2048-LABEL: masked_gather_v32i32:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.s, vl32
; VBITS_GE_2048-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    cmpeq p2.s, p0/z, z0.s, #0
; VBITS_GE_2048-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cval = load <32 x i32>, <32 x i32>* %a
  %ptrs = load <32 x i32*>, <32 x i32*>* %b
  %mask = icmp eq <32 x i32> %cval, zeroinitializer
  %vals = call <32 x i32> @llvm.masked.gather.v32i32(<32 x i32*> %ptrs, i32 8, <32 x i1> %mask, <32 x i32> undef)
  store <32 x i32> %vals, <32 x i32>* %a
  ret void
}

;
; LD1D
;

; Scalarize 1 x i64 gathers
define void @masked_gather_v1i64(<1 x i64>* %a, <1 x i64*>* %b) #0 {
; CHECK-LABEL: masked_gather_v1i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr d0, [x0]
; CHECK-NEXT:    fmov x8, d0
; CHECK-NEXT:    // implicit-def: $d0
; CHECK-NEXT:    cbnz x8, .LBB15_2
; CHECK-NEXT:  // %bb.1: // %cond.load
; CHECK-NEXT:    ldr d0, [x1]
; CHECK-NEXT:    fmov x8, d0
; CHECK-NEXT:    ldr d0, [x8]
; CHECK-NEXT:  .LBB15_2: // %else
; CHECK-NEXT:    str d0, [x0]
; CHECK-NEXT:    ret
  %cval = load <1 x i64>, <1 x i64>* %a
  %ptrs = load <1 x i64*>, <1 x i64*>* %b
  %mask = icmp eq <1 x i64> %cval, zeroinitializer
  %vals = call <1 x i64> @llvm.masked.gather.v1i64(<1 x i64*> %ptrs, i32 8, <1 x i1> %mask, <1 x i64> undef)
  store <1 x i64> %vals, <1 x i64>* %a
  ret void
}

define void @masked_gather_v2i64(<2 x i64>* %a, <2 x i64*>* %b) #0 {
; CHECK-LABEL: masked_gather_v2i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr q0, [x0]
; CHECK-NEXT:    ldr q1, [x1]
; CHECK-NEXT:    ptrue p0.d, vl2
; CHECK-NEXT:    cmeq v0.2d, v0.2d, #0
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1d { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    str q0, [x0]
; CHECK-NEXT:    ret
  %cval = load <2 x i64>, <2 x i64>* %a
  %ptrs = load <2 x i64*>, <2 x i64*>* %b
  %mask = icmp eq <2 x i64> %cval, zeroinitializer
  %vals = call <2 x i64> @llvm.masked.gather.v2i64(<2 x i64*> %ptrs, i32 8, <2 x i1> %mask, <2 x i64> undef)
  store <2 x i64> %vals, <2 x i64>* %a
  ret void
}

define void @masked_gather_v4i64(<4 x i64>* %a, <4 x i64*>* %b) #0 {
; CHECK-LABEL: masked_gather_v4i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    ld1d { z0.d }, p0/z, [x0]
; CHECK-NEXT:    ld1d { z1.d }, p0/z, [x1]
; CHECK-NEXT:    cmpeq p1.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1d { z0.d }, p1/z, [z1.d]
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %cval = load <4 x i64>, <4 x i64>* %a
  %ptrs = load <4 x i64*>, <4 x i64*>* %b
  %mask = icmp eq <4 x i64> %cval, zeroinitializer
  %vals = call <4 x i64> @llvm.masked.gather.v4i64(<4 x i64*> %ptrs, i32 8, <4 x i1> %mask, <4 x i64> undef)
  store <4 x i64> %vals, <4 x i64>* %a
  ret void
}

define void @masked_gather_v8i64(<8 x i64>* %a, <8 x i64*>* %b) #0 {
; Ensure sensible type legalisation.
; VBITS_EQ_256-LABEL: masked_gather_v8i64:
; VBITS_EQ_256:       // %bb.0:
; VBITS_EQ_256-NEXT:    mov x8, #4
; VBITS_EQ_256-NEXT:    ptrue p0.d, vl4
; VBITS_EQ_256-NEXT:    ld1d { z0.d }, p0/z, [x0, x8, lsl #3]
; VBITS_EQ_256-NEXT:    ld1d { z1.d }, p0/z, [x0]
; VBITS_EQ_256-NEXT:    ld1d { z2.d }, p0/z, [x1, x8, lsl #3]
; VBITS_EQ_256-NEXT:    ld1d { z3.d }, p0/z, [x1]
; VBITS_EQ_256-NEXT:    cmpeq p1.d, p0/z, z0.d, #0
; VBITS_EQ_256-NEXT:    cmpeq p2.d, p0/z, z1.d, #0
; VBITS_EQ_256-NEXT:    ld1d { z0.d }, p1/z, [z2.d]
; VBITS_EQ_256-NEXT:    ld1d { z1.d }, p2/z, [z3.d]
; VBITS_EQ_256-NEXT:    st1d { z0.d }, p0, [x0, x8, lsl #3]
; VBITS_EQ_256-NEXT:    st1d { z1.d }, p0, [x0]
; VBITS_EQ_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: masked_gather_v8i64:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    ld1d { z0.d }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_512-NEXT:    cmpeq p1.d, p0/z, z0.d, #0
; VBITS_GE_512-NEXT:    ld1d { z0.d }, p1/z, [z1.d]
; VBITS_GE_512-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_512-NEXT:    ret

  %cval = load <8 x i64>, <8 x i64>* %a
  %ptrs = load <8 x i64*>, <8 x i64*>* %b
  %mask = icmp eq <8 x i64> %cval, zeroinitializer
  %vals = call <8 x i64> @llvm.masked.gather.v8i64(<8 x i64*> %ptrs, i32 8, <8 x i1> %mask, <8 x i64> undef)
  store <8 x i64> %vals, <8 x i64>* %a
  ret void
}

define void @masked_gather_v16i64(<16 x i64>* %a, <16 x i64*>* %b) #0 {
; VBITS_GE_1024-LABEL: masked_gather_v16i64:
; VBITS_GE_1024:       // %bb.0:
; VBITS_GE_1024-NEXT:    ptrue p0.d, vl16
; VBITS_GE_1024-NEXT:    ld1d { z0.d }, p0/z, [x0]
; VBITS_GE_1024-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_1024-NEXT:    cmpeq p1.d, p0/z, z0.d, #0
; VBITS_GE_1024-NEXT:    ld1d { z0.d }, p1/z, [z1.d]
; VBITS_GE_1024-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_1024-NEXT:    ret
  %cval = load <16 x i64>, <16 x i64>* %a
  %ptrs = load <16 x i64*>, <16 x i64*>* %b
  %mask = icmp eq <16 x i64> %cval, zeroinitializer
  %vals = call <16 x i64> @llvm.masked.gather.v16i64(<16 x i64*> %ptrs, i32 8, <16 x i1> %mask, <16 x i64> undef)
  store <16 x i64> %vals, <16 x i64>* %a
  ret void
}

define void @masked_gather_v32i64(<32 x i64>* %a, <32 x i64*>* %b) #0 {
; VBITS_GE_2048-LABEL: masked_gather_v32i64:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z0.d }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_2048-NEXT:    cmpeq p1.d, p0/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1d { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cval = load <32 x i64>, <32 x i64>* %a
  %ptrs = load <32 x i64*>, <32 x i64*>* %b
  %mask = icmp eq <32 x i64> %cval, zeroinitializer
  %vals = call <32 x i64> @llvm.masked.gather.v32i64(<32 x i64*> %ptrs, i32 8, <32 x i1> %mask, <32 x i64> undef)
  store <32 x i64> %vals, <32 x i64>* %a
  ret void
}

;
; LD1H (float)
;

define void @masked_gather_v2f16(<2 x half>* %a, <2 x half*>* %b) #0 {
; CHECK-LABEL: masked_gather_v2f16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr s0, [x0]
; CHECK-NEXT:    movi d2, #0000000000000000
; CHECK-NEXT:    ldr q1, [x1]
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    fcmeq v0.4h, v0.4h, #0.0
; CHECK-NEXT:    umov w8, v0.h[0]
; CHECK-NEXT:    umov w9, v0.h[1]
; CHECK-NEXT:    fmov s0, w8
; CHECK-NEXT:    mov v0.s[1], w9
; CHECK-NEXT:    shl v0.2s, v0.2s, #16
; CHECK-NEXT:    sshr v0.2s, v0.2s, #16
; CHECK-NEXT:    fmov w9, s0
; CHECK-NEXT:    mov w8, v0.s[1]
; CHECK-NEXT:    mov v2.h[0], w9
; CHECK-NEXT:    mov v2.h[1], w8
; CHECK-NEXT:    shl v0.4h, v2.4h, #15
; CHECK-NEXT:    sshr v0.4h, v0.4h, #15
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1h { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    uzp1 z0.s, z0.s, z0.s
; CHECK-NEXT:    uzp1 z0.h, z0.h, z0.h
; CHECK-NEXT:    str s0, [x0]
; CHECK-NEXT:    ret
  %cval = load <2 x half>, <2 x half>* %a
  %ptrs = load <2 x half*>, <2 x half*>* %b
  %mask = fcmp oeq <2 x half> %cval, zeroinitializer
  %vals = call <2 x half> @llvm.masked.gather.v2f16(<2 x half*> %ptrs, i32 8, <2 x i1> %mask, <2 x half> undef)
  store <2 x half> %vals, <2 x half>* %a
  ret void
}

define void @masked_gather_v4f16(<4 x half>* %a, <4 x half*>* %b) #0 {
; CHECK-LABEL: masked_gather_v4f16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr d0, [x0]
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    ld1d { z1.d }, p0/z, [x1]
; CHECK-NEXT:    fcmeq v0.4h, v0.4h, #0.0
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1h { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    uzp1 z0.s, z0.s, z0.s
; CHECK-NEXT:    uzp1 z0.h, z0.h, z0.h
; CHECK-NEXT:    str d0, [x0]
; CHECK-NEXT:    ret
  %cval = load <4 x half>, <4 x half>* %a
  %ptrs = load <4 x half*>, <4 x half*>* %b
  %mask = fcmp oeq <4 x half> %cval, zeroinitializer
  %vals = call <4 x half> @llvm.masked.gather.v4f16(<4 x half*> %ptrs, i32 8, <4 x i1> %mask, <4 x half> undef)
  store <4 x half> %vals, <4 x half>* %a
  ret void
}

define void @masked_gather_v8f16(<8 x half>* %a, <8 x half*>* %b) #0 {
; VBITS_GE_512-LABEL: masked_gather_v8f16:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ldr q0, [x0]
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_512-NEXT:    fcmeq v0.8h, v0.8h, #0.0
; VBITS_GE_512-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; VBITS_GE_512-NEXT:    ld1h { z0.d }, p0/z, [z1.d]
; VBITS_GE_512-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_512-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_512-NEXT:    str q0, [x0]
; VBITS_GE_512-NEXT:    ret
  %cval = load <8 x half>, <8 x half>* %a
  %ptrs = load <8 x half*>, <8 x half*>* %b
  %mask = fcmp oeq <8 x half> %cval, zeroinitializer
  %vals = call <8 x half> @llvm.masked.gather.v8f16(<8 x half*> %ptrs, i32 8, <8 x i1> %mask, <8 x half> undef)
  store <8 x half> %vals, <8 x half>* %a
  ret void
}

define void @masked_gather_v16f16(<16 x half>* %a, <16 x half*>* %b) #0 {
; VBITS_GE_1024-LABEL: masked_gather_v16f16:
; VBITS_GE_1024:       // %bb.0:
; VBITS_GE_1024-NEXT:    ptrue p0.h, vl16
; VBITS_GE_1024-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_1024-NEXT:    ptrue p1.d, vl16
; VBITS_GE_1024-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_1024-NEXT:    fcmeq p2.h, p0/z, z0.h, #0.0
; VBITS_GE_1024-NEXT:    mov z0.h, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_1024-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_1024-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_1024-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_1024-NEXT:    ld1h { z0.d }, p1/z, [z1.d]
; VBITS_GE_1024-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_1024-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_1024-NEXT:    st1h { z0.h }, p0, [x0]
; VBITS_GE_1024-NEXT:    ret
  %cval = load <16 x half>, <16 x half>* %a
  %ptrs = load <16 x half*>, <16 x half*>* %b
  %mask = fcmp oeq <16 x half> %cval, zeroinitializer
  %vals = call <16 x half> @llvm.masked.gather.v16f16(<16 x half*> %ptrs, i32 8, <16 x i1> %mask, <16 x half> undef)
  store <16 x half> %vals, <16 x half>* %a
  ret void
}

define void @masked_gather_v32f16(<32 x half>* %a, <32 x half*>* %b) #0 {
; VBITS_GE_2048-LABEL: masked_gather_v32f16:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.h, vl32
; VBITS_GE_2048-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.h, p0/z, z0.h, #0.0
; VBITS_GE_2048-NEXT:    mov z0.h, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1h { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_2048-NEXT:    st1h { z0.h }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cval = load <32 x half>, <32 x half>* %a
  %ptrs = load <32 x half*>, <32 x half*>* %b
  %mask = fcmp oeq <32 x half> %cval, zeroinitializer
  %vals = call <32 x half> @llvm.masked.gather.v32f16(<32 x half*> %ptrs, i32 8, <32 x i1> %mask, <32 x half> undef)
  store <32 x half> %vals, <32 x half>* %a
  ret void
}

;
; LD1W (float)
;

define void @masked_gather_v2f32(<2 x float>* %a, <2 x float*>* %b) #0 {
; CHECK-LABEL: masked_gather_v2f32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr d0, [x0]
; CHECK-NEXT:    ldr q1, [x1]
; CHECK-NEXT:    ptrue p0.d, vl2
; CHECK-NEXT:    fcmeq v0.2s, v0.2s, #0.0
; CHECK-NEXT:    ushll v0.2d, v0.2s, #0
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1w { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    xtn v0.2s, v0.2d
; CHECK-NEXT:    str d0, [x0]
; CHECK-NEXT:    ret
  %cval = load <2 x float>, <2 x float>* %a
  %ptrs = load <2 x float*>, <2 x float*>* %b
  %mask = fcmp oeq <2 x float> %cval, zeroinitializer
  %vals = call <2 x float> @llvm.masked.gather.v2f32(<2 x float*> %ptrs, i32 8, <2 x i1> %mask, <2 x float> undef)
  store <2 x float> %vals, <2 x float>* %a
  ret void
}

define void @masked_gather_v4f32(<4 x float>* %a, <4 x float*>* %b) #0 {
; CHECK-LABEL: masked_gather_v4f32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr q0, [x0]
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    ld1d { z1.d }, p0/z, [x1]
; CHECK-NEXT:    fcmeq v0.4s, v0.4s, #0.0
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1w { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    uzp1 z0.s, z0.s, z0.s
; CHECK-NEXT:    str q0, [x0]
; CHECK-NEXT:    ret
  %cval = load <4 x float>, <4 x float>* %a
  %ptrs = load <4 x float*>, <4 x float*>* %b
  %mask = fcmp oeq <4 x float> %cval, zeroinitializer
  %vals = call <4 x float> @llvm.masked.gather.v4f32(<4 x float*> %ptrs, i32 8, <4 x i1> %mask, <4 x float> undef)
  store <4 x float> %vals, <4 x float>* %a
  ret void
}

define void @masked_gather_v8f32(<8 x float>* %a, <8 x float*>* %b) #0 {
; VBITS_GE_512-LABEL: masked_gather_v8f32:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.s, vl8
; VBITS_GE_512-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ptrue p1.d, vl8
; VBITS_GE_512-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_512-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_512-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_512-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_512-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_512-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_512-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_512-NEXT:    ret
  %cval = load <8 x float>, <8 x float>* %a
  %ptrs = load <8 x float*>, <8 x float*>* %b
  %mask = fcmp oeq <8 x float> %cval, zeroinitializer
  %vals = call <8 x float> @llvm.masked.gather.v8f32(<8 x float*> %ptrs, i32 8, <8 x i1> %mask, <8 x float> undef)
  store <8 x float> %vals, <8 x float>* %a
  ret void
}

define void @masked_gather_v16f32(<16 x float>* %a, <16 x float*>* %b) #0 {
; VBITS_GE_1024-LABEL: masked_gather_v16f32:
; VBITS_GE_1024:       // %bb.0:
; VBITS_GE_1024-NEXT:    ptrue p0.s, vl16
; VBITS_GE_1024-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_1024-NEXT:    ptrue p1.d, vl16
; VBITS_GE_1024-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_1024-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_1024-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_1024-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_1024-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_1024-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_1024-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_1024-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_1024-NEXT:    ret
  %cval = load <16 x float>, <16 x float>* %a
  %ptrs = load <16 x float*>, <16 x float*>* %b
  %mask = fcmp oeq <16 x float> %cval, zeroinitializer
  %vals = call <16 x float> @llvm.masked.gather.v16f32(<16 x float*> %ptrs, i32 8, <16 x i1> %mask, <16 x float> undef)
  store <16 x float> %vals, <16 x float>* %a
  ret void
}

define void @masked_gather_v32f32(<32 x float>* %a, <32 x float*>* %b) #0 {
; VBITS_GE_2048-LABEL: masked_gather_v32f32:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.s, vl32
; VBITS_GE_2048-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_2048-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cval = load <32 x float>, <32 x float>* %a
  %ptrs = load <32 x float*>, <32 x float*>* %b
  %mask = fcmp oeq <32 x float> %cval, zeroinitializer
  %vals = call <32 x float> @llvm.masked.gather.v32f32(<32 x float*> %ptrs, i32 8, <32 x i1> %mask, <32 x float> undef)
  store <32 x float> %vals, <32 x float>* %a
  ret void
}

;
; LD1D (float)
;

; Scalarize 1 x double gathers
define void @masked_gather_v1f64(<1 x double>* %a, <1 x double*>* %b) #0 {
; CHECK-LABEL: masked_gather_v1f64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr d0, [x0]
; CHECK-NEXT:    fcmp d0, #0.0
; CHECK-NEXT:    // implicit-def: $d0
; CHECK-NEXT:    b.ne .LBB31_2
; CHECK-NEXT:  // %bb.1: // %cond.load
; CHECK-NEXT:    ldr d0, [x1]
; CHECK-NEXT:    fmov x8, d0
; CHECK-NEXT:    ldr d0, [x8]
; CHECK-NEXT:  .LBB31_2: // %else
; CHECK-NEXT:    str d0, [x0]
; CHECK-NEXT:    ret
  %cval = load <1 x double>, <1 x double>* %a
  %ptrs = load <1 x double*>, <1 x double*>* %b
  %mask = fcmp oeq <1 x double> %cval, zeroinitializer
  %vals = call <1 x double> @llvm.masked.gather.v1f64(<1 x double*> %ptrs, i32 8, <1 x i1> %mask, <1 x double> undef)
  store <1 x double> %vals, <1 x double>* %a
  ret void
}

define void @masked_gather_v2f64(<2 x double>* %a, <2 x double*>* %b) #0 {
; CHECK-LABEL: masked_gather_v2f64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ldr q0, [x0]
; CHECK-NEXT:    ldr q1, [x1]
; CHECK-NEXT:    ptrue p0.d, vl2
; CHECK-NEXT:    fcmeq v0.2d, v0.2d, #0.0
; CHECK-NEXT:    cmpne p0.d, p0/z, z0.d, #0
; CHECK-NEXT:    ld1d { z0.d }, p0/z, [z1.d]
; CHECK-NEXT:    str q0, [x0]
; CHECK-NEXT:    ret
  %cval = load <2 x double>, <2 x double>* %a
  %ptrs = load <2 x double*>, <2 x double*>* %b
  %mask = fcmp oeq <2 x double> %cval, zeroinitializer
  %vals = call <2 x double> @llvm.masked.gather.v2f64(<2 x double*> %ptrs, i32 8, <2 x i1> %mask, <2 x double> undef)
  store <2 x double> %vals, <2 x double>* %a
  ret void
}

define void @masked_gather_v4f64(<4 x double>* %a, <4 x double*>* %b) #0 {
; CHECK-LABEL: masked_gather_v4f64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    ld1d { z0.d }, p0/z, [x0]
; CHECK-NEXT:    ld1d { z1.d }, p0/z, [x1]
; CHECK-NEXT:    fcmeq p1.d, p0/z, z0.d, #0.0
; CHECK-NEXT:    ld1d { z0.d }, p1/z, [z1.d]
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %cval = load <4 x double>, <4 x double>* %a
  %ptrs = load <4 x double*>, <4 x double*>* %b
  %mask = fcmp oeq <4 x double> %cval, zeroinitializer
  %vals = call <4 x double> @llvm.masked.gather.v4f64(<4 x double*> %ptrs, i32 8, <4 x i1> %mask, <4 x double> undef)
  store <4 x double> %vals, <4 x double>* %a
  ret void
}

define void @masked_gather_v8f64(<8 x double>* %a, <8 x double*>* %b) #0 {
; VBITS_GE_512-LABEL: masked_gather_v8f64:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    ld1d { z0.d }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_512-NEXT:    fcmeq p1.d, p0/z, z0.d, #0.0
; VBITS_GE_512-NEXT:    ld1d { z0.d }, p1/z, [z1.d]
; VBITS_GE_512-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_512-NEXT:    ret
  %cval = load <8 x double>, <8 x double>* %a
  %ptrs = load <8 x double*>, <8 x double*>* %b
  %mask = fcmp oeq <8 x double> %cval, zeroinitializer
  %vals = call <8 x double> @llvm.masked.gather.v8f64(<8 x double*> %ptrs, i32 8, <8 x i1> %mask, <8 x double> undef)
  store <8 x double> %vals, <8 x double>* %a
  ret void
}

define void @masked_gather_v16f64(<16 x double>* %a, <16 x double*>* %b) #0 {
; VBITS_GE_1024-LABEL: masked_gather_v16f64:
; VBITS_GE_1024:       // %bb.0:
; VBITS_GE_1024-NEXT:    ptrue p0.d, vl16
; VBITS_GE_1024-NEXT:    ld1d { z0.d }, p0/z, [x0]
; VBITS_GE_1024-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_1024-NEXT:    fcmeq p1.d, p0/z, z0.d, #0.0
; VBITS_GE_1024-NEXT:    ld1d { z0.d }, p1/z, [z1.d]
; VBITS_GE_1024-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_1024-NEXT:    ret
  %cval = load <16 x double>, <16 x double>* %a
  %ptrs = load <16 x double*>, <16 x double*>* %b
  %mask = fcmp oeq <16 x double> %cval, zeroinitializer
  %vals = call <16 x double> @llvm.masked.gather.v16f64(<16 x double*> %ptrs, i32 8, <16 x i1> %mask, <16 x double> undef)
  store <16 x double> %vals, <16 x double>* %a
  ret void
}

define void @masked_gather_v32f64(<32 x double>* %a, <32 x double*>* %b) #0 {
; VBITS_GE_2048-LABEL: masked_gather_v32f64:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z0.d }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p0/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p1.d, p0/z, z0.d, #0.0
; VBITS_GE_2048-NEXT:    ld1d { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cval = load <32 x double>, <32 x double>* %a
  %ptrs = load <32 x double*>, <32 x double*>* %b
  %mask = fcmp oeq <32 x double> %cval, zeroinitializer
  %vals = call <32 x double> @llvm.masked.gather.v32f64(<32 x double*> %ptrs, i32 8, <32 x i1> %mask, <32 x double> undef)
  store <32 x double> %vals, <32 x double>* %a
  ret void
}

; The above tests test the types, the below tests check that the addressing
; modes still function

; NOTE: This produces an non-optimal addressing mode due to a temporary workaround
define void @masked_gather_32b_scaled_sext_f16(<32 x half>* %a, <32 x i32>* %b, half* %base) #0 {
; VBITS_GE_2048-LABEL: masked_gather_32b_scaled_sext_f16:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.h, vl32
; VBITS_GE_2048-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1sw { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.h, p0/z, z0.h, #0.0
; VBITS_GE_2048-NEXT:    mov z0.h, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1h { z0.d }, p1/z, [x2, z1.d, lsl #1]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_2048-NEXT:    st1h { z0.h }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x half>, <32 x half>* %a
  %idxs = load <32 x i32>, <32 x i32>* %b
  %ext = sext <32 x i32> %idxs to <32 x i64>
  %ptrs = getelementptr half, half* %base, <32 x i64> %ext
  %mask = fcmp oeq <32 x half> %cvals, zeroinitializer
  %vals = call <32 x half> @llvm.masked.gather.v32f16(<32 x half*> %ptrs, i32 8, <32 x i1> %mask, <32 x half> undef)
  store <32 x half> %vals, <32 x half>* %a
  ret void
}

; NOTE: This produces an non-optimal addressing mode due to a temporary workaround
define void @masked_gather_32b_scaled_sext_f32(<32 x float>* %a, <32 x i32>* %b, float* %base) #0 {
; VBITS_GE_2048-LABEL: masked_gather_32b_scaled_sext_f32:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.s, vl32
; VBITS_GE_2048-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1sw { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_2048-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1w { z0.d }, p1/z, [x2, z1.d, lsl #2]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x float>, <32 x float>* %a
  %idxs = load <32 x i32>, <32 x i32>* %b
  %ext = sext <32 x i32> %idxs to <32 x i64>
  %ptrs = getelementptr float, float* %base, <32 x i64> %ext
  %mask = fcmp oeq <32 x float> %cvals, zeroinitializer
  %vals = call <32 x float> @llvm.masked.gather.v32f32(<32 x float*> %ptrs, i32 8, <32 x i1> %mask, <32 x float> undef)
  store <32 x float> %vals, <32 x float>* %a
  ret void
}

; NOTE: This produces an non-optimal addressing mode due to a temporary workaround
define void @masked_gather_32b_scaled_sext_f64(<32 x double>* %a, <32 x i32>* %b, double* %base) #0 {
; VBITS_GE_2048-LABEL: masked_gather_32b_scaled_sext_f64:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z0.d }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ld1sw { z1.d }, p0/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p1.d, p0/z, z0.d, #0.0
; VBITS_GE_2048-NEXT:    ld1d { z0.d }, p1/z, [x2, z1.d, lsl #3]
; VBITS_GE_2048-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x double>, <32 x double>* %a
  %idxs = load <32 x i32>, <32 x i32>* %b
  %ext = sext <32 x i32> %idxs to <32 x i64>
  %ptrs = getelementptr double, double* %base, <32 x i64> %ext
  %mask = fcmp oeq <32 x double> %cvals, zeroinitializer
  %vals = call <32 x double> @llvm.masked.gather.v32f64(<32 x double*> %ptrs, i32 8, <32 x i1> %mask, <32 x double> undef)
  store <32 x double> %vals, <32 x double>* %a
  ret void
}

; NOTE: This produces an non-optimal addressing mode due to a temporary workaround
define void @masked_gather_32b_scaled_zext(<32 x half>* %a, <32 x i32>* %b, half* %base) #0 {
; VBITS_GE_2048-LABEL: masked_gather_32b_scaled_zext:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.h, vl32
; VBITS_GE_2048-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1w { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.h, p0/z, z0.h, #0.0
; VBITS_GE_2048-NEXT:    mov z0.h, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1h { z0.d }, p1/z, [x2, z1.d, lsl #1]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_2048-NEXT:    st1h { z0.h }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x half>, <32 x half>* %a
  %idxs = load <32 x i32>, <32 x i32>* %b
  %ext = zext <32 x i32> %idxs to <32 x i64>
  %ptrs = getelementptr half, half* %base, <32 x i64> %ext
  %mask = fcmp oeq <32 x half> %cvals, zeroinitializer
  %vals = call <32 x half> @llvm.masked.gather.v32f16(<32 x half*> %ptrs, i32 8, <32 x i1> %mask, <32 x half> undef)
  store <32 x half> %vals, <32 x half>* %a
  ret void
}

; NOTE: This produces an non-optimal addressing mode due to a temporary workaround
define void @masked_gather_32b_unscaled_sext(<32 x half>* %a, <32 x i32>* %b, i8* %base) #0 {
; VBITS_GE_2048-LABEL: masked_gather_32b_unscaled_sext:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.h, vl32
; VBITS_GE_2048-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1sw { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.h, p0/z, z0.h, #0.0
; VBITS_GE_2048-NEXT:    mov z0.h, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1h { z0.d }, p1/z, [x2, z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_2048-NEXT:    st1h { z0.h }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x half>, <32 x half>* %a
  %idxs = load <32 x i32>, <32 x i32>* %b
  %ext = sext <32 x i32> %idxs to <32 x i64>
  %byte_ptrs = getelementptr i8, i8* %base, <32 x i64> %ext
  %ptrs = bitcast <32 x i8*> %byte_ptrs to <32 x half*>
  %mask = fcmp oeq <32 x half> %cvals, zeroinitializer
  %vals = call <32 x half> @llvm.masked.gather.v32f16(<32 x half*> %ptrs, i32 8, <32 x i1> %mask, <32 x half> undef)
  store <32 x half> %vals, <32 x half>* %a
  ret void
}

; NOTE: This produces an non-optimal addressing mode due to a temporary workaround
define void @masked_gather_32b_unscaled_zext(<32 x half>* %a, <32 x i32>* %b, i8* %base) #0 {
; VBITS_GE_2048-LABEL: masked_gather_32b_unscaled_zext:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.h, vl32
; VBITS_GE_2048-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1w { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.h, p0/z, z0.h, #0.0
; VBITS_GE_2048-NEXT:    mov z0.h, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1h { z0.d }, p1/z, [x2, z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    uzp1 z0.h, z0.h, z0.h
; VBITS_GE_2048-NEXT:    st1h { z0.h }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x half>, <32 x half>* %a
  %idxs = load <32 x i32>, <32 x i32>* %b
  %ext = zext <32 x i32> %idxs to <32 x i64>
  %byte_ptrs = getelementptr i8, i8* %base, <32 x i64> %ext
  %ptrs = bitcast <32 x i8*> %byte_ptrs to <32 x half*>
  %mask = fcmp oeq <32 x half> %cvals, zeroinitializer
  %vals = call <32 x half> @llvm.masked.gather.v32f16(<32 x half*> %ptrs, i32 8, <32 x i1> %mask, <32 x half> undef)
  store <32 x half> %vals, <32 x half>* %a
  ret void
}

define void @masked_gather_64b_scaled(<32 x float>* %a, <32 x i64>* %b, float* %base) #0 {
; VBITS_GE_2048-LABEL: masked_gather_64b_scaled:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.s, vl32
; VBITS_GE_2048-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_2048-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1w { z0.d }, p1/z, [x2, z1.d, lsl #2]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x float>, <32 x float>* %a
  %idxs = load <32 x i64>, <32 x i64>* %b
  %ptrs = getelementptr float, float* %base, <32 x i64> %idxs
  %mask = fcmp oeq <32 x float> %cvals, zeroinitializer
  %vals = call <32 x float> @llvm.masked.gather.v32f32(<32 x float*> %ptrs, i32 8, <32 x i1> %mask, <32 x float> undef)
  store <32 x float> %vals, <32 x float>* %a
  ret void
}

define void @masked_gather_64b_unscaled(<32 x float>* %a, <32 x i64>* %b, i8* %base) #0 {
; VBITS_GE_2048-LABEL: masked_gather_64b_unscaled:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.s, vl32
; VBITS_GE_2048-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_2048-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1w { z0.d }, p1/z, [x2, z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x float>, <32 x float>* %a
  %idxs = load <32 x i64>, <32 x i64>* %b
  %byte_ptrs = getelementptr i8, i8* %base, <32 x i64> %idxs
  %ptrs = bitcast <32 x i8*> %byte_ptrs to <32 x float*>
  %mask = fcmp oeq <32 x float> %cvals, zeroinitializer
  %vals = call <32 x float> @llvm.masked.gather.v32f32(<32 x float*> %ptrs, i32 8, <32 x i1> %mask, <32 x float> undef)
  store <32 x float> %vals, <32 x float>* %a
  ret void
}

; FIXME: This case does not yet codegen well due to deficiencies in opcode selection
define void @masked_gather_vec_plus_reg(<32 x float>* %a, <32 x i8*>* %b, i64 %off) #0 {
; VBITS_GE_2048-LABEL: masked_gather_vec_plus_reg:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.s, vl32
; VBITS_GE_2048-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    mov z2.d, x2
; VBITS_GE_2048-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_2048-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    add z1.d, p1/m, z1.d, z2.d
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x float>, <32 x float>* %a
  %bases = load <32 x i8*>, <32 x i8*>* %b
  %byte_ptrs = getelementptr i8, <32 x i8*> %bases, i64 %off
  %ptrs = bitcast <32 x i8*> %byte_ptrs to <32 x float*>
  %mask = fcmp oeq <32 x float> %cvals, zeroinitializer
  %vals = call <32 x float> @llvm.masked.gather.v32f32(<32 x float*> %ptrs, i32 8, <32 x i1> %mask, <32 x float> undef)
  store <32 x float> %vals, <32 x float>* %a
  ret void
}

; FIXME: This case does not yet codegen well due to deficiencies in opcode selection
define void @masked_gather_vec_plus_imm(<32 x float>* %a, <32 x i8*>* %b) #0 {
; VBITS_GE_2048-LABEL: masked_gather_vec_plus_imm:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.s, vl32
; VBITS_GE_2048-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    mov z2.d, #4 // =0x4
; VBITS_GE_2048-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_2048-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    add z1.d, p1/m, z1.d, z2.d
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x float>, <32 x float>* %a
  %bases = load <32 x i8*>, <32 x i8*>* %b
  %byte_ptrs = getelementptr i8, <32 x i8*> %bases, i64 4
  %ptrs = bitcast <32 x i8*> %byte_ptrs to <32 x float*>
  %mask = fcmp oeq <32 x float> %cvals, zeroinitializer
  %vals = call <32 x float> @llvm.masked.gather.v32f32(<32 x float*> %ptrs, i32 8, <32 x i1> %mask, <32 x float> undef)
  store <32 x float> %vals, <32 x float>* %a
  ret void
}

define void @masked_gather_passthru(<32 x float>* %a, <32 x float*>* %b, <32 x float>* %c) #0 {
; VBITS_GE_2048-LABEL: masked_gather_passthru:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.s, vl32
; VBITS_GE_2048-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    ld1w { z2.s }, p0/z, [x2]
; VBITS_GE_2048-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_2048-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    sel z0.s, p2, z0.s, z2.s
; VBITS_GE_2048-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x float>, <32 x float>* %a
  %ptrs = load <32 x float*>, <32 x float*>* %b
  %passthru = load <32 x float>, <32 x float>* %c
  %mask = fcmp oeq <32 x float> %cvals, zeroinitializer
  %vals = call <32 x float> @llvm.masked.gather.v32f32(<32 x float*> %ptrs, i32 8, <32 x i1> %mask, <32 x float> %passthru)
  store <32 x float> %vals, <32 x float>* %a
  ret void
}

define void @masked_gather_passthru_0(<32 x float>* %a, <32 x float*>* %b) #0 {
; VBITS_GE_2048-LABEL: masked_gather_passthru_0:
; VBITS_GE_2048:       // %bb.0:
; VBITS_GE_2048-NEXT:    ptrue p0.s, vl32
; VBITS_GE_2048-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_2048-NEXT:    ptrue p1.d, vl32
; VBITS_GE_2048-NEXT:    ld1d { z1.d }, p1/z, [x1]
; VBITS_GE_2048-NEXT:    fcmeq p2.s, p0/z, z0.s, #0.0
; VBITS_GE_2048-NEXT:    mov z0.s, p2/z, #-1 // =0xffffffffffffffff
; VBITS_GE_2048-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_2048-NEXT:    cmpne p1.d, p1/z, z0.d, #0
; VBITS_GE_2048-NEXT:    ld1w { z0.d }, p1/z, [z1.d]
; VBITS_GE_2048-NEXT:    uzp1 z0.s, z0.s, z0.s
; VBITS_GE_2048-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_2048-NEXT:    ret
  %cvals = load <32 x float>, <32 x float>* %a
  %ptrs = load <32 x float*>, <32 x float*>* %b
  %mask = fcmp oeq <32 x float> %cvals, zeroinitializer
  %vals = call <32 x float> @llvm.masked.gather.v32f32(<32 x float*> %ptrs, i32 8, <32 x i1> %mask, <32 x float> zeroinitializer)
  store <32 x float> %vals, <32 x float>* %a
  ret void
}

declare <2 x i8> @llvm.masked.gather.v2i8(<2 x i8*>, i32, <2 x i1>, <2 x i8>)
declare <4 x i8> @llvm.masked.gather.v4i8(<4 x i8*>, i32, <4 x i1>, <4 x i8>)
declare <8 x i8> @llvm.masked.gather.v8i8(<8 x i8*>, i32, <8 x i1>, <8 x i8>)
declare <16 x i8> @llvm.masked.gather.v16i8(<16 x i8*>, i32, <16 x i1>, <16 x i8>)
declare <32 x i8> @llvm.masked.gather.v32i8(<32 x i8*>, i32, <32 x i1>, <32 x i8>)

declare <2 x i16> @llvm.masked.gather.v2i16(<2 x i16*>, i32, <2 x i1>, <2 x i16>)
declare <4 x i16> @llvm.masked.gather.v4i16(<4 x i16*>, i32, <4 x i1>, <4 x i16>)
declare <8 x i16> @llvm.masked.gather.v8i16(<8 x i16*>, i32, <8 x i1>, <8 x i16>)
declare <16 x i16> @llvm.masked.gather.v16i16(<16 x i16*>, i32, <16 x i1>, <16 x i16>)
declare <32 x i16> @llvm.masked.gather.v32i16(<32 x i16*>, i32, <32 x i1>, <32 x i16>)

declare <2 x i32> @llvm.masked.gather.v2i32(<2 x i32*>, i32, <2 x i1>, <2 x i32>)
declare <4 x i32> @llvm.masked.gather.v4i32(<4 x i32*>, i32, <4 x i1>, <4 x i32>)
declare <8 x i32> @llvm.masked.gather.v8i32(<8 x i32*>, i32, <8 x i1>, <8 x i32>)
declare <16 x i32> @llvm.masked.gather.v16i32(<16 x i32*>, i32, <16 x i1>, <16 x i32>)
declare <32 x i32> @llvm.masked.gather.v32i32(<32 x i32*>, i32, <32 x i1>, <32 x i32>)

declare <1 x i64> @llvm.masked.gather.v1i64(<1 x i64*>, i32, <1 x i1>, <1 x i64>)
declare <2 x i64> @llvm.masked.gather.v2i64(<2 x i64*>, i32, <2 x i1>, <2 x i64>)
declare <4 x i64> @llvm.masked.gather.v4i64(<4 x i64*>, i32, <4 x i1>, <4 x i64>)
declare <8 x i64> @llvm.masked.gather.v8i64(<8 x i64*>, i32, <8 x i1>, <8 x i64>)
declare <16 x i64> @llvm.masked.gather.v16i64(<16 x i64*>, i32, <16 x i1>, <16 x i64>)
declare <32 x i64> @llvm.masked.gather.v32i64(<32 x i64*>, i32, <32 x i1>, <32 x i64>)

declare <2 x half> @llvm.masked.gather.v2f16(<2 x half*>, i32, <2 x i1>, <2 x half>)
declare <4 x half> @llvm.masked.gather.v4f16(<4 x half*>, i32, <4 x i1>, <4 x half>)
declare <8 x half> @llvm.masked.gather.v8f16(<8 x half*>, i32, <8 x i1>, <8 x half>)
declare <16 x half> @llvm.masked.gather.v16f16(<16 x half*>, i32, <16 x i1>, <16 x half>)
declare <32 x half> @llvm.masked.gather.v32f16(<32 x half*>, i32, <32 x i1>, <32 x half>)

declare <2 x float> @llvm.masked.gather.v2f32(<2 x float*>, i32, <2 x i1>, <2 x float>)
declare <4 x float> @llvm.masked.gather.v4f32(<4 x float*>, i32, <4 x i1>, <4 x float>)
declare <8 x float> @llvm.masked.gather.v8f32(<8 x float*>, i32, <8 x i1>, <8 x float>)
declare <16 x float> @llvm.masked.gather.v16f32(<16 x float*>, i32, <16 x i1>, <16 x float>)
declare <32 x float> @llvm.masked.gather.v32f32(<32 x float*>, i32, <32 x i1>, <32 x float>)

declare <1 x double> @llvm.masked.gather.v1f64(<1 x double*>, i32, <1 x i1>, <1 x double>)
declare <2 x double> @llvm.masked.gather.v2f64(<2 x double*>, i32, <2 x i1>, <2 x double>)
declare <4 x double> @llvm.masked.gather.v4f64(<4 x double*>, i32, <4 x i1>, <4 x double>)
declare <8 x double> @llvm.masked.gather.v8f64(<8 x double*>, i32, <8 x i1>, <8 x double>)
declare <16 x double> @llvm.masked.gather.v16f64(<16 x double*>, i32, <16 x i1>, <16 x double>)
declare <32 x double> @llvm.masked.gather.v32f64(<32 x double*>, i32, <32 x i1>, <32 x double>)

attributes #0 = { "target-features"="+sve" }
