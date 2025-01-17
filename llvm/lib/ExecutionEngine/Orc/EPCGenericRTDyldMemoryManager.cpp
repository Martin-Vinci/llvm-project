//===----- EPCGenericRTDyldMemoryManager.cpp - EPC-bbasde MemMgr -----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/ExecutionEngine/Orc/EPCGenericRTDyldMemoryManager.h"
#include "llvm/ExecutionEngine/Orc/EPCGenericMemoryAccess.h"
#include "llvm/ExecutionEngine/Orc/Shared/OrcRTBridge.h"
#include "llvm/Support/Alignment.h"
#include "llvm/Support/FormatVariadic.h"

#define DEBUG_TYPE "orc"

namespace llvm {
namespace orc {

Expected<std::unique_ptr<EPCGenericRTDyldMemoryManager>>
EPCGenericRTDyldMemoryManager::CreateWithDefaultBootstrapSymbols(
    ExecutorProcessControl &EPC) {
  SymbolAddrs SAs;
  if (auto Err = EPC.getBootstrapSymbols(
          {{SAs.Instance, rt::SimpleExecutorMemoryManagerInstanceName},
           {SAs.Reserve, rt::SimpleExecutorMemoryManagerReserveWrapperName},
           {SAs.Finalize, rt::SimpleExecutorMemoryManagerFinalizeWrapperName},
           {SAs.Deallocate,
            rt::SimpleExecutorMemoryManagerDeallocateWrapperName},
           {SAs.RegisterEHFrame,
            rt::RegisterEHFrameSectionCustomDirectWrapperName},
           {SAs.DeregisterEHFrame,
            rt::DeregisterEHFrameSectionCustomDirectWrapperName}}))
    return std::move(Err);
  return std::make_unique<EPCGenericRTDyldMemoryManager>(EPC, std::move(SAs));
}

EPCGenericRTDyldMemoryManager::EPCGenericRTDyldMemoryManager(
    ExecutorProcessControl &EPC, SymbolAddrs SAs)
    : EPC(EPC), SAs(std::move(SAs)) {
  LLVM_DEBUG(dbgs() << "Created remote allocator " << (void *)this << "\n");
}

EPCGenericRTDyldMemoryManager::~EPCGenericRTDyldMemoryManager() {
  LLVM_DEBUG(dbgs() << "Destroyed remote allocator " << (void *)this << "\n");
  if (!ErrMsg.empty())
    errs() << "Destroying with existing errors:\n" << ErrMsg << "\n";

  Error Err = Error::success();
  if (auto Err2 = EPC.callSPSWrapper<
                  rt::SPSSimpleExecutorMemoryManagerDeallocateSignature>(
          SAs.Reserve.getValue(), Err, SAs.Instance, FinalizedAllocs)) {
    // FIXME: Report errors through EPC once that functionality is available.
    logAllUnhandledErrors(std::move(Err2), errs(), "");
    return;
  }

  if (Err)
    logAllUnhandledErrors(std::move(Err), errs(), "");
}

uint8_t *EPCGenericRTDyldMemoryManager::allocateCodeSection(
    uintptr_t Size, unsigned Alignment, unsigned SectionID,
    StringRef SectionName) {
  std::lock_guard<std::mutex> Lock(M);
  LLVM_DEBUG({
    dbgs() << "Allocator " << (void *)this << " allocating code section "
           << SectionName << ": size = " << formatv("{0:x}", Size)
           << " bytes, alignment = " << Alignment << "\n";
  });
  auto &Seg = Unmapped.back().CodeAllocs;
  Seg.emplace_back(Size, Alignment);
  return reinterpret_cast<uint8_t *>(
      alignAddr(Seg.back().Contents.get(), Align(Alignment)));
}

uint8_t *EPCGenericRTDyldMemoryManager::allocateDataSection(
    uintptr_t Size, unsigned Alignment, unsigned SectionID,
    StringRef SectionName, bool IsReadOnly) {
  std::lock_guard<std::mutex> Lock(M);
  LLVM_DEBUG({
    dbgs() << "Allocator " << (void *)this << " allocating "
           << (IsReadOnly ? "ro" : "rw") << "-data section " << SectionName
           << ": size = " << formatv("{0:x}", Size) << " bytes, alignment "
           << Alignment << ")\n";
  });

  auto &Seg =
      IsReadOnly ? Unmapped.back().RODataAllocs : Unmapped.back().RWDataAllocs;

  Seg.emplace_back(Size, Alignment);
  return reinterpret_cast<uint8_t *>(
      alignAddr(Seg.back().Contents.get(), Align(Alignment)));
}

void EPCGenericRTDyldMemoryManager::reserveAllocationSpace(
    uintptr_t CodeSize, uint32_t CodeAlign, uintptr_t RODataSize,
    uint32_t RODataAlign, uintptr_t RWDataSize, uint32_t RWDataAlign) {

  {
    std::lock_guard<std::mutex> Lock(M);
    // If there's already an error then bail out.
    if (!ErrMsg.empty())
      return;

    if (!isPowerOf2_32(CodeAlign) || CodeAlign > EPC.getPageSize()) {
      ErrMsg = "Invalid code alignment in reserveAllocationSpace";
      return;
    }
    if (!isPowerOf2_32(RODataAlign) || RODataAlign > EPC.getPageSize()) {
      ErrMsg = "Invalid ro-data alignment in reserveAllocationSpace";
      return;
    }
    if (!isPowerOf2_32(RWDataAlign) || RWDataAlign > EPC.getPageSize()) {
      ErrMsg = "Invalid rw-data alignment in reserveAllocationSpace";
      return;
    }
  }

  uint64_t TotalSize = 0;
  TotalSize += alignTo(CodeSize, EPC.getPageSize());
  TotalSize += alignTo(RODataSize, EPC.getPageSize());
  TotalSize += alignTo(RWDataSize, EPC.getPageSize());

  LLVM_DEBUG({
    dbgs() << "Allocator " << (void *)this << " reserving "
           << formatv("{0:x}", TotalSize) << " bytes.\n";
  });

  Expected<ExecutorAddr> TargetAllocAddr((ExecutorAddr()));
  if (auto Err = EPC.callSPSWrapper<
                 rt::SPSSimpleExecutorMemoryManagerReserveSignature>(
          SAs.Reserve.getValue(), TargetAllocAddr, SAs.Instance, TotalSize)) {
    std::lock_guard<std::mutex> Lock(M);
    ErrMsg = toString(std::move(Err));
    return;
  }
  if (!TargetAllocAddr) {
    std::lock_guard<std::mutex> Lock(M);
    ErrMsg = toString(TargetAllocAddr.takeError());
    return;
  }

  std::lock_guard<std::mutex> Lock(M);
  Unmapped.push_back(AllocGroup());
  Unmapped.back().RemoteCode = {
      *TargetAllocAddr, ExecutorAddrDiff(alignTo(CodeSize, EPC.getPageSize()))};
  Unmapped.back().RemoteROData = {
      Unmapped.back().RemoteCode.End,
      ExecutorAddrDiff(alignTo(RODataSize, EPC.getPageSize()))};
  Unmapped.back().RemoteRWData = {
      Unmapped.back().RemoteROData.End,
      ExecutorAddrDiff(alignTo(RWDataSize, EPC.getPageSize()))};
}

bool EPCGenericRTDyldMemoryManager::needsToReserveAllocationSpace() {
  return true;
}

void EPCGenericRTDyldMemoryManager::registerEHFrames(uint8_t *Addr,
                                                     uint64_t LoadAddr,
                                                     size_t Size) {
  LLVM_DEBUG({
    dbgs() << "Allocator " << (void *)this << " added unfinalized eh-frame "
           << formatv("[ {0:x} {1:x} ]", LoadAddr, LoadAddr + Size) << "\n";
  });
  std::lock_guard<std::mutex> Lock(M);
  // Bail out early if there's already an error.
  if (!ErrMsg.empty())
    return;

  ExecutorAddr LA(LoadAddr);
  for (auto &Alloc : llvm::reverse(Unfinalized)) {
    if (Alloc.RemoteCode.contains(LA) || Alloc.RemoteROData.contains(LA) ||
        Alloc.RemoteRWData.contains(LA)) {
      Alloc.UnfinalizedEHFrames.push_back({LA, Size});
      return;
    }
  }
  ErrMsg = "eh-frame does not lie inside unfinalized alloc";
}

void EPCGenericRTDyldMemoryManager::deregisterEHFrames() {
  // This is a no-op for us: We've registered a deallocation action for it.
}

void EPCGenericRTDyldMemoryManager::notifyObjectLoaded(
    RuntimeDyld &Dyld, const object::ObjectFile &Obj) {
  std::lock_guard<std::mutex> Lock(M);
  LLVM_DEBUG(dbgs() << "Allocator " << (void *)this << " applied mappings:\n");
  for (auto &ObjAllocs : Unmapped) {
    mapAllocsToRemoteAddrs(Dyld, ObjAllocs.CodeAllocs,
                           ObjAllocs.RemoteCode.Start);
    mapAllocsToRemoteAddrs(Dyld, ObjAllocs.RODataAllocs,
                           ObjAllocs.RemoteROData.Start);
    mapAllocsToRemoteAddrs(Dyld, ObjAllocs.RWDataAllocs,
                           ObjAllocs.RemoteRWData.Start);
    Unfinalized.push_back(std::move(ObjAllocs));
  }
  Unmapped.clear();
}

bool EPCGenericRTDyldMemoryManager::finalizeMemory(std::string *ErrMsg) {
  LLVM_DEBUG(dbgs() << "Allocator " << (void *)this << " finalizing:\n");

  // If there's an error then bail out here.
  std::vector<AllocGroup> Allocs;
  {
    std::lock_guard<std::mutex> Lock(M);
    if (ErrMsg && !this->ErrMsg.empty()) {
      *ErrMsg = std::move(this->ErrMsg);
      return true;
    }
    std::swap(Allocs, Unfinalized);
  }

  // Loop over unfinalized objects to make finalization requests.
  for (auto &ObjAllocs : Allocs) {

    tpctypes::WireProtectionFlags SegProts[3] = {
        tpctypes::toWireProtectionFlags(
            static_cast<sys::Memory::ProtectionFlags>(sys::Memory::MF_READ |
                                                      sys::Memory::MF_EXEC)),
        tpctypes::toWireProtectionFlags(sys::Memory::MF_READ),
        tpctypes::toWireProtectionFlags(
            static_cast<sys::Memory::ProtectionFlags>(sys::Memory::MF_READ |
                                                      sys::Memory::MF_WRITE))};

    ExecutorAddrRange *RemoteAddrs[3] = {&ObjAllocs.RemoteCode,
                                         &ObjAllocs.RemoteROData,
                                         &ObjAllocs.RemoteRWData};

    std::vector<Alloc> *SegSections[3] = {&ObjAllocs.CodeAllocs,
                                          &ObjAllocs.RODataAllocs,
                                          &ObjAllocs.RWDataAllocs};

    tpctypes::FinalizeRequest FR;
    std::unique_ptr<char[]> AggregateContents[3];

    for (unsigned I = 0; I != 3; ++I) {
      FR.Segments.push_back({});
      auto &Seg = FR.Segments.back();
      Seg.Prot = SegProts[I];
      Seg.Addr = RemoteAddrs[I]->Start;
      for (auto &SecAlloc : *SegSections[I]) {
        Seg.Size = alignTo(Seg.Size, SecAlloc.Align);
        Seg.Size += SecAlloc.Size;
      }
      AggregateContents[I] = std::make_unique<char[]>(Seg.Size);
      size_t SecOffset = 0;
      for (auto &SecAlloc : *SegSections[I]) {
        SecOffset = alignTo(SecOffset, SecAlloc.Align);
        memcpy(&AggregateContents[I][SecOffset],
               reinterpret_cast<const char *>(
                   alignAddr(SecAlloc.Contents.get(), Align(SecAlloc.Align))),
               SecAlloc.Size);
        SecOffset += SecAlloc.Size;
        // FIXME: Can we reset SecAlloc.Content here, now that it's copied into
        // the aggregated content?
      }
      Seg.Content = {AggregateContents[I].get(), SecOffset};
    }

    for (auto &Frame : ObjAllocs.UnfinalizedEHFrames)
      FR.Actions.push_back({{SAs.RegisterEHFrame, Frame.Addr, Frame.Size},
                            {SAs.DeregisterEHFrame, Frame.Addr, Frame.Size}});

    // We'll also need to make an extra allocation for the eh-frame wrapper call
    // arguments.
    Error FinalizeErr = Error::success();
    if (auto Err = EPC.callSPSWrapper<
                   rt::SPSSimpleExecutorMemoryManagerFinalizeSignature>(
            SAs.Finalize.getValue(), FinalizeErr, SAs.Instance,
            std::move(FR))) {
      std::lock_guard<std::mutex> Lock(M);
      this->ErrMsg = toString(std::move(Err));
      dbgs() << "Serialization error: " << this->ErrMsg << "\n";
      if (ErrMsg)
        *ErrMsg = this->ErrMsg;
      return true;
    }
    if (FinalizeErr) {
      std::lock_guard<std::mutex> Lock(M);
      this->ErrMsg = toString(std::move(FinalizeErr));
      dbgs() << "Finalization error: " << this->ErrMsg << "\n";
      if (ErrMsg)
        *ErrMsg = this->ErrMsg;
      return true;
    }
  }

  return false;
}

void EPCGenericRTDyldMemoryManager::mapAllocsToRemoteAddrs(
    RuntimeDyld &Dyld, std::vector<Alloc> &Allocs, ExecutorAddr NextAddr) {
  for (auto &Alloc : Allocs) {
    NextAddr.setValue(alignTo(NextAddr.getValue(), Alloc.Align));
    LLVM_DEBUG({
      dbgs() << "     " << static_cast<void *>(Alloc.Contents.get()) << " -> "
             << format("0x%016" PRIx64, NextAddr.getValue()) << "\n";
    });
    Dyld.mapSectionAddress(reinterpret_cast<const void *>(alignAddr(
                               Alloc.Contents.get(), Align(Alloc.Align))),
                           NextAddr.getValue());
    Alloc.RemoteAddr = NextAddr;
    // Only advance NextAddr if it was non-null to begin with,
    // otherwise leave it as null.
    if (NextAddr)
      NextAddr += ExecutorAddrDiff(Alloc.Size);
  }
}

} // end namespace orc
} // end namespace llvm
