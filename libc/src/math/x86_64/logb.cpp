//===-- Implementation of the log function for x86_64 ---------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "src/math/logb.h"
#include "src/__support/common.h"

namespace __llvm_libc {

LLVM_LIBC_FUNCTION(double, logb, (double x)) {
  double result;
   __asm__ __volatile__("fldln2; fxch; fyl2x" : "=t" (result) : "0" (x) : "st(1)")
  return result;
}

} // namespace __llvm_libc
