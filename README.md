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

Copy and customize the splat configuration:

```bash
cp config/splat.example.yaml config/splat.us.yaml
# Edit config/splat.us.yaml with your game's details
```

Key things to configure:
- `target_path`: Path to your game binary
- `sha1`: SHA1 checksum of the binary
- `vram`: Load address (check with a PSX debugger or readelf)
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
# Run asm-differ to see differences
python3 tools/asm-differ/diff.py -mwo FunctionName
```

### 5. Iterate

Adjust the C code until the diff shows a match. Common techniques:
- Reorder variable declarations
- Adjust types (s32 vs int, u8* vs char*)
- Use temp variables
- Check decomp-permuter for variations

### 6. Verify

```bash
make check
```

## Tools Reference

| Tool | Purpose | Usage |
|------|---------|-------|
| **splat** | Binary splitting/extraction | `make extract` |
| **m2c** | MIPS to C decompiler | `python3 tools/m2c/m2c.py file.s` |
| **asm-differ** | Compare ASM output | `python3 tools/asm-differ/diff.py -mwo FuncName` |
| **maspsx** | PSX assembler macros | Used automatically by Makefile |
| **decomp-permuter** | Find matching code variations | See tool README |

## Resources

### Documentation

- [splat Wiki](https://github.com/ethteck/splat/wiki)
- [decomp.me](https://decomp.me/) - Collaborative decompilation platform
- [PSX Dev Wiki](https://psx-dev.miraheze.org/)

### Community

- [PSX.Dev Discord](https://discord.gg/QByKPpH)
- [Decomp Discord](https://discord.gg/sutqNShRRs)

### Example Projects

- [sotn-decomp](https://github.com/Xeeynamo/sotn-decomp) - Castlevania: Symphony of the Night
- [open-ribbon](https://github.com/open-ribbon/open-ribbon) - Vib-Ribbon
- [esa-new](https://github.com/mkst/esa-new) - Reference PSX decomp setup

## Known Limitations

### Not Yet Supported

- **dosemu2**: Required for some legacy PSY-Q DOS tools. Not packaged in Nix yet.
  - Workaround: Use Docker, or native Linux builds of PSY-Q tools (cc1-psx-26)
  - See: https://github.com/sozud/dosemu-deb

- **Saturn support**: Would require `sh-elf` binutils and Saturn-specific tooling.

- **PSP support**: Would require Allegrex toolchain (allegrex-as, mwccpsp).

## Contributing

Contributions are welcome! Please open issues or PRs for:
- Bug fixes
- Documentation improvements
- Additional platform support (Saturn, PSP)
- Packaging of tools like dosemu2

## License

This template is released under the MIT License. See [LICENSE](LICENSE) for details.

Note: The tools referenced as submodules have their own licenses. The PSX compiler binaries may have licensing restrictions from Sony - use them responsibly for educational/preservation purposes.

## Acknowledgments

This template is built on the incredible work of the decompilation community:

- [@ethteck](https://github.com/ethteck) - splat, decomp.me, frogress
- [@simonlindholm](https://github.com/simonlindholm) - asm-differ, decomp-permuter
- [@matt-kempster](https://github.com/matt-kempster) - m2c (mips2c)
- [@mkst](https://github.com/mkst) - maspsx, esa-new
- The entire PSX and N64 decomp communities
