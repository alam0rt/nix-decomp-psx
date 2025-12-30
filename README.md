# nix-decomp-psx

A Nix flake template for PlayStation 1 (PSX) game decompilation projects.

This template provides a complete development environment and project structure for decompiling PSX games, based on conventions established by projects like [sotn-decomp](https://github.com/Xeeynamo/sotn-decomp), [open-ribbon](https://github.com/open-ribbon/open-ribbon), and other PSX decompilation efforts.

## Features

- **Reproducible environment** via Nix flakes
- **MIPS cross-compilation toolchain** (binutils, GCC)
- **Python environment** with splat, spimdisasm, rabbitizer pre-configured
- **Standard project structure** matching community conventions
- **Tool submodules** (asm-differ, m2c, maspsx, decomp-permuter)
- **Template Makefile** with common targets

## Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- Git

### Enable Nix Flakes

If you haven't already, enable flakes in your Nix configuration:

```bash
# Add to ~/.config/nix/nix.conf or /etc/nix/nix.conf
experimental-features = nix-command flakes
```

## Quick Start

### 1. Create a New Project

```bash
# Create a new directory for your project
mkdir my-psx-decomp
cd my-psx-decomp

# Initialize from template
nix flake init -t github:user/nix-decomp-psx

# Initialize git repository
git init
git submodule update --init --recursive
```

### 2. Download Toolchain

The PSX compiler (cc1-psx-26) and other binary tools need to be downloaded:

```bash
./tools/download-toolchain.sh
```

### 3. Add Your Game Binary

Place your game's PSX executable in the `disks/` directory:

```
disks/
└── us/
    └── SLUS_000.00    # Your game's executable
```

### 4. Configure Splat

**Option A: Generate config automatically (recommended)**

```bash
# Enter dev environment first
nix develop

# Generate a config file from your binary
python3 -m splat create_config disks/us/SLUS_XXX.XX

# This creates a yaml file based on the ROM header
# Move it to the config directory
mv *.yaml config/splat.us.yaml
```

**Option B: Use the template**

```bash
cp config/splat.example.yaml config/splat.us.yaml
# Edit config/splat.us.yaml with your game's details
```

Key things to configure:
- `name`: Your game's name
- `sha1`: SHA1 checksum (`sha1sum disks/us/SLUS_XXX.XX`)
- `target_path`: Path to your game binary
- `vram`: Load address (typically 0x80010000 for PSX)
- `segments`: Binary segment definitions

### 5. Enter Development Environment

```bash
nix develop
```

This drops you into a shell with all tools available.

### 6. Extract and Build

```bash
# Extract/disassemble the binary
make extract

# Build (initially will just reassemble the extracted ASM)
make

# Verify the build matches the original
make check
```

## Project Structure

```
my-psx-decomp/
├── flake.nix                 # Nix flake (dev environment)
├── flake.lock                # Locked dependencies
├── Makefile                  # Build system
├── diff_settings.py          # asm-differ configuration
│
├── config/
│   ├── splat.us.yaml         # Splat configuration
│   └── symbols.us.txt        # Symbol definitions
│
├── src/                      # Decompiled C source
│   └── main.c
│
├── include/                  # Header files
│   └── common.h
│
├── asm/                      # Extracted assembly (generated)
│   └── us/
│
├── assets/                   # Extracted assets (generated)
├── build/                    # Build output (generated)
│
├── disks/                    # Original game binaries
│   └── us/
│       └── SLUS_000.00
│
├── bin/                      # Toolchain binaries
│   ├── cc1-psx-26
│   └── ...
│
└── tools/                    # Tool submodules
    ├── asm-differ/
    ├── m2c/
    ├── maspsx/
    ├── decomp-permuter/
    └── requirements-python.txt
```

## Decompilation Workflow

### 1. Identify a Function

Use a disassembler (Ghidra, IDA, or the extracted ASM files) to find a function to decompile.

### 2. Get Initial C Code

Use m2c to get a starting point:

```bash
# Decompile a function from ASM
python3 tools/m2c/m2c.py asm/us/main/func_80012345.s
```

### 3. Create C File

Create a new C file in `src/` and add the decompiled function. Update `config/splat.us.yaml` to use `c` type instead of `asm` for that segment.

### 4. Compare with Original

```bash
# Run asm-differ to see differences (use aliases for convenience)
python3 tools/asm-differ/diff.py -mwo3 FunctionName

# Or with the alias (after sourcing tools/.bash_aliases):
ad FunctionName

# Watch mode - auto-updates on file changes:
ad FunctionName --watch
```

### 5. Iterate

Adjust the C code until the diff shows a match. Common techniques:
- Reorder variable declarations
- Adjust types (s32 vs int, u8* vs char*)
- Use temp variables
- Check decomp-permuter for variations

### 6. Use decomp-permuter

When stuck on register allocation or instruction ordering:

```bash
# Import function for permutation
python3 tools/decomp-permuter/import.py src/main.c

# Run permuter (finds code variations that match better)
python3 tools/decomp-permuter/permuter.py nonmatchings/FunctionName --best-only -j4
```

### 7. Verify

```bash
make check
```

## Modern Workflow (No Wine/DOSEmu Required!)

This template uses the **modern PSX decompilation approach** pioneered by [mkst/esa](https://github.com/mkst/esa):

### The Toolchain

| Component | Purpose |
|-----------|---------|
| **old-gcc** | Native Linux builds of GCC 2.x compilers from [decompals/old-gcc](https://github.com/decompals/old-gcc) |
| **maspsx** | Python script that transforms GCC's assembly output to match PSY-Q's ASPSX.EXE |
| **GNU as** | Standard MIPS assembler from binutils (via Nix) |
| **GNU ld** | Standard MIPS linker from binutils (via Nix) |

### Why This Works

The original PSY-Q SDK used a customized GCC compiler. The key insight is that:

1. **GCC 2.95.2** produces nearly identical code to PSY-Q 4.6's `CC1PSX.EXE`
2. **maspsx** handles the small differences in assembly macro expansion
3. Native Linux tools eliminate the need for wine/dosemu2

### Compiler Version Mapping

| PSY-Q Version | GCC Version | ASPSX Version |
|--------------|-------------|---------------|
| PSY-Q 4.6 | GCC 2.95.2 | 2.86 |
| PSY-Q 4.4/4.5 | GCC 2.91.66 (egcs) | 2.79/2.81 |
| PSY-Q 4.0-4.3 | GCC 2.8.x | 2.56-2.77 |
| PSY-Q 3.x | GCC 2.7.2 | 2.21-2.34 |

Detect your game's compiler with:
```bash
make detect-compiler
```

## Tools Reference

| Tool | Purpose | Usage |
|------|---------|-------|
| **splat** | Binary splitting/extraction | `make extract` |
| **m2c** | MIPS to C decompiler | `make decompile FUNC=func_name` |
| **asm-differ** | Compare ASM output | `make diff FUNC=FuncName` |
| **maspsx** | PSX assembler macros | Used automatically by Makefile |
| **decomp-permuter** | Find matching code variations | `make permuter FUNC=FuncName` |
| **ctx.py** | Generate m2c context | `make context` |

### Bash Aliases

For convenience, add to your shell:
```bash
source tools/.bash_aliases

# Then use:
ad FuncName      # asm-differ
m2c file.s       # m2c with context
di src/main.c    # decomp-permuter import
dp nonmatchings/ # run permuter
```

## Resources

### Documentation

- [splat Wiki](https://github.com/ethteck/splat/wiki)
- [decomp.me](https://decomp.me/) - Collaborative decompilation platform
- [PSX Dev Wiki](https://psx-dev.miraheze.org/)
- [maspsx README](https://github.com/mkst/maspsx) - Modern ASPSX replacement
- [esa Wiki](https://github.com/mkst/esa/wiki) - Reference PSX decomp project

### Community

- [PSX.Dev Discord](https://discord.gg/QByKPpH)
- [Decomp Discord](https://discord.gg/sutqNShRRs)

### Example Projects

- [sotn-decomp](https://github.com/Xeeynamo/sotn-decomp) - Castlevania: Symphony of the Night
- [open-ribbon](https://github.com/open-ribbon/open-ribbon) - Vib-Ribbon
- [esa](https://github.com/mkst/esa) - Evo's Space Adventures (modern toolchain reference)
- [sssv](https://github.com/mkst/sssv) - Space Station Silicon Valley (N64/PSX)

## Known Limitations

### GTE Instructions

Some PSX games use GTE (Geometry Transformation Engine) coprocessor instructions that require special handling:

```s
# These may appear as raw bytes in disassembly:
.byte 0x00, 0xe8, 0xc8, 0x48  # Actually: ctc2 instruction
```

You may need to add GTE macros to `include/gte.inc` for these cases.

### dosemu2 (Legacy)

If you need to run original 16-bit DOS PSY-Q tools:
- Not packaged in Nix
- Workaround: Docker or Ubuntu packages from https://github.com/sozud/dosemu-deb

### Other Platforms

- **Saturn**: Would require `sh-elf` binutils and Saturn-specific tooling
- **PSP**: Would require Allegrex toolchain (allegrex-as, mwccpsp)

## Contributing

Contributions are welcome! Please open issues or PRs for:
- Bug fixes
- Documentation improvements
- Additional platform support (Saturn, PSP)
- Packaging of tools like dosemu2

## License

This template is released under the MIT License. See [LICENSE](LICENSE) for details.

Note: The tools referenced as submodules have their own licenses. The GCC binaries are GNU GPL. Use responsibly for educational/preservation purposes.

## Acknowledgments

This template is built on the incredible work of the decompilation community:

- [@ethteck](https://github.com/ethteck) - splat, decomp.me, frogress
- [@simonlindholm](https://github.com/simonlindholm) - asm-differ, decomp-permuter
- [@matt-kempster](https://github.com/matt-kempster) - m2c (mips2c)
- [@mkst](https://github.com/mkst) - maspsx, esa, old-gcc toolchain approach
- [@decompals](https://github.com/decompals) - old-gcc builds
- The entire PSX and N64 decomp communities

