//===------- EPCGenericDylibManager.cpp -- Dylib management via EPC -------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/ExecutionEngine/Orc/EPCGenericDylibManager.h"

#include "llvm/ExecutionEngine/Orc/Core.h"
#include "llvm/ExecutionEngine/Orc/Shared/OrcRTBridge.h"
#include "llvm/ExecutionEngine/Orc/Shared/SimpleRemoteEPCUtils.h"

namespace llvm {
namespace orc {
namespace shared {

template <>
class SPSSerializationTraits<SPSRemoteSymbolLookupSetElement,
                             SymbolLookupSet::value_type> {
public:
  static size_t size(const SymbolLookupSet::value_type &V) {
    return SPSArgList<SPSString, bool>::size(
        *V.first, V.second == SymbolLookupFlags::RequiredSymbol);
  }

  static bool serialize(SPSOutputBuffer &OB,
                        const SymbolLookupSet::value_type &V) {
    return SPSArgList<SPSString, bool>::serialize(
        OB, *V.first, V.second == SymbolLookupFlags::RequiredSymbol);
  }
};

template <>
class TrivialSPSSequenceSerialization<SPSRemoteSymbolLookupSetElement,
                                      SymbolLookupSet> {
public:
  static constexpr bool available = true;
};

template <>
class SPSSerializationTraits<SPSRemoteSymbolLookup,
                             ExecutorProcessControl::LookupRequest> {
  using MemberSerialization =
      SPSArgList<SPSExecutorAddr, SPSRemoteSymbolLookupSet>;

public:
  static size_t size(const ExecutorProcessControl::LookupRequest &LR) {
    return MemberSerialization::size(ExecutorAddr(LR.Handle), LR.Symbols);
  }

  static bool serialize(SPSOutputBuffer &OB,
                        const ExecutorProcessControl::LookupRequest &LR) {
    return MemberSerialization::serialize(OB, ExecutorAddr(LR.Handle),
                                          LR.Symbols);
  }
};

} // end namespace shared

Expected<EPCGenericDylibManager>
EPCGenericDylibManager::CreateWithDefaultBootstrapSymbols(
    ExecutorProcessControl &EPC) {
  SymbolAddrs SAs;
  if (auto Err = EPC.getBootstrapSymbols(
          {{SAs.Instance, rt::SimpleExecutorDylibManagerInstanceName},
           {SAs.Open, rt::SimpleExecutorDylibManagerOpenWrapperName},
           {SAs.Lookup, rt::SimpleExecutorDylibManagerLookupWrapperName}}))
    return std::move(Err);
  return EPCGenericDylibManager(EPC, std::move(SAs));
}

Expected<tpctypes::DylibHandle> EPCGenericDylibManager::open(StringRef Path,
                                                             uint64_t Mode) {
  Expected<tpctypes::DylibHandle> H(0);
  if (auto Err =
          EPC.callSPSWrapper<rt::SPSSimpleExecutorDylibManagerOpenSignature>(
              SAs.Open.getValue(), H, SAs.Instance, Path, Mode))
    return std::move(Err);
  return H;
}

Expected<std::vector<ExecutorAddr>>
EPCGenericDylibManager::lookup(tpctypes::DylibHandle H,
                               const SymbolLookupSet &Lookup) {
  Expected<std::vector<ExecutorAddr>> Result((std::vector<ExecutorAddr>()));
  if (auto Err =
          EPC.callSPSWrapper<rt::SPSSimpleExecutorDylibManagerLookupSignature>(
              SAs.Lookup.getValue(), Result, SAs.Instance, H, Lookup))
    return std::move(Err);
  return Result;
}

Expected<std::vector<ExecutorAddr>>
EPCGenericDylibManager::lookup(tpctypes::DylibHandle H,
                               const RemoteSymbolLookupSet &Lookup) {
  Expected<std::vector<ExecutorAddr>> Result((std::vector<ExecutorAddr>()));
  if (auto Err =
          EPC.callSPSWrapper<rt::SPSSimpleExecutorDylibManagerLookupSignature>(
              SAs.Lookup.getValue(), Result, SAs.Instance, H, Lookup))
    return std::move(Err);
  return Result;
}

} // end namespace orc
} // end namespace llvm
