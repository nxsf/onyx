# Target

{{ paper-toc }}

The standard defines identifiers for some instruction set architectures ([ISA](#target-isa){paper-link}); instruction set extensions ([ISE](#target-ise){paper-link}); processing units ([PU](#target-pu){paper-link}); operating systems ([OS](#target-os){paper-link}); and application binary interfaces ([ABI](#target-abi){paper-link}). These are referenced as *target parts*.

A PU identifier may replace a combination of ISA with ISE. For example, `skylake` is a shortcut for x86 with certain set of extensions, such as [SEE](https://en.wikipedia.org/wiki/Streaming_SIMD_Extensions) and [ADX](https://en.wikipedia.org/wiki/Intel_ADX). However, even a concrete PU may have floating ISE; for instance, Skylake has [AVX-512](https://en.wikipedia.org/wiki/AVX-512) [enabled on Xeon processors only](https://en.wikipedia.org/wiki/Skylake_(microarchitecture)#cite_note-bitsnchips-2).

There are no any guarantees for supporting a certain identifier between major standard versions.

A complete target nomenclature has the following syntax:

```abnf {.spec-syntax paper-noindex}
target =
  ((? ISA ?) | (? PU ?)),
  ["[", {("+" | "-"), (? ISE ?)}, "]"],
  ["-", (? OS ?), ["[", (? VER ?)"]"]],
  {"-", (? ABI ?), ["[", (? VER ?), "]"]};
```

, for example `aarch64-eabi[3]-gnu` or `skylake[+avx512]-win32[>=8]-msvc`. {paper-noindex}

## ISA

The standard identifies the following instruction set architectures: {paper-noindex}

  1. `i386` — [IA-32](https://en.wikipedia.org/wiki/IA-32);
  1. `x86_64` — [x86](https://en.wikipedia.org/wiki/X86);

## ISE

The standard identifies the following instruction set extensions. {paper-noindex}

Some extensions are enabled by *(default)* for an architecture.

### x86

  1. `sse` (default) — [SSE](https://en.wikipedia.org/wiki/Streaming_SIMD_Extensions);
  1. `sse2` — [SSE2](https://en.wikipedia.org/wiki/SSE2);

## PU

The standard identifies the following processing unit models: {paper-noindex}

### x86

  1. `skylake` — the Intel Skylake CPU. It has the following deviations from the default x86 ISE: `[+avx512-mre]`;

### PTX

  1. `turing`

## OS

The standard identifies the following operating systems: {paper-noindex}

  1. `none` — no OS, i.e. the baremetal environment;
  1. `eabi`
  1. `linux`
  1. `win32`
  1. `darwin`
  1. `freebsd`
  1. `netbsd`

## ABI

The standard identifies the following ABIs: {paper-noindex}

  1. `glibc` — GNU LibC, applicable for Linux and Windows targets under Cygwin, MinGW and MinGW-w64;
  1. `muslc` — Musl LibC, applicable for Linux targets;
  1. `msvc` — native Windows runtime;
  1. `ulibc`
  1. `bsdc`
