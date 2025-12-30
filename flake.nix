{
  description = "PSX Decompilation Development Environment Template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # Allow unfree packages (some tools may need this)
          config.allowUnfree = true;
        };

        # Python environment with all required packages for PSX decomp
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          # Core decomp tools
          # splat64  # Install via pip in shell hook - version pinning needed
          # spimdisasm
          # rabbitizer

          # Build/dev dependencies
          pycparser
          pillow
          toml
          pyyaml
          intervaltree
          watchdog
          python-Levenshtein
          cxxfilt
          tabulate
          requests
          graphviz

          # Development tools
          black
          pre-commit

          # Package management (for installing pinned versions)
          pip
          virtualenv
        ]);

        # Cross-compilation toolchain for MIPS (PSX uses MIPS R3000)
        mipsCross = pkgs.pkgsCross.mipsel-linux-gnu;

      in
      {
        devShells.default = pkgs.mkShell {
          name = "psx-decomp";

          buildInputs = with pkgs; [
            # ===========================================
            # Core build tools
            # ===========================================
            gnumake
            ninja
            cmake
            pkg-config

            # ===========================================
            # MIPS cross-compilation toolchain
            # ===========================================
            # Binutils for MIPS (linker, objcopy, as, etc.)
            pkgsCross.mipsel-linux-gnu.buildPackages.binutils

            # GCC for MIPS (used for preprocessing and some compilation)
            pkgsCross.mipsel-linux-gnu.buildPackages.gcc

            # ===========================================
            # Python environment
            # ===========================================
            pythonEnv

            # ===========================================
            # Version control & utilities
            # ===========================================
            git
            curl
            wget
            unzip
            p7zip

            # ===========================================
            # Code formatting & analysis
            # ===========================================
            clang-tools  # includes clang-format

            # ===========================================
            # Rust toolchain (for custom tools like sotn-lint)
            # ===========================================
            rustc
            cargo

            # ===========================================
            # Go toolchain (for asset tools)
            # ===========================================
            go

            # ===========================================
            # CD/ISO utilities
            # ===========================================
            bchunk  # Convert bin/cue to iso

            # ===========================================
            # ELF utilities
            # ===========================================
            libelf

            # ===========================================
            # Misc utilities
            # ===========================================
            coreutils
            gawk
            gnused
            gnugrep
            findutils
            file
            which
            iconv

            # TODO: dosemu2 - Required for running legacy PSY-Q DOS tools
            # dosemu2 is not in nixpkgs. Options:
            # 1. Package dosemu2 for Nix (complex, requires fdpp)
            # 2. Use Docker/Podman fallback for DOS tools
            # 3. Use pre-built Linux binaries where available (cc1-psx-26)
            # See: https://github.com/sozud/dosemu-deb for Ubuntu packages
            # For now, we use native Linux builds of the PSY-Q compiler

            # TODO: Saturn support would need sh-elf binutils
            # pkgsCross.sh4-linux-gnu.buildPackages.binutils
          ];

          shellHook = ''
            echo "🎮 PSX Decompilation Environment"
            echo "================================"

            # Create and activate Python virtual environment for pinned packages
            if [ ! -d .venv ]; then
              echo "Creating Python virtual environment..."
              python -m venv .venv
            fi
            source .venv/bin/activate

            # Install pinned Python packages if requirements exist
            if [ -f tools/requirements-python.txt ]; then
              pip install -q -r tools/requirements-python.txt
            fi

            # Ensure bin directory exists for downloaded tools
            mkdir -p bin

            # Download PSX compiler tools if not present
            if [ ! -f bin/cc1-psx-26 ]; then
              echo ""
              echo "⚠️  PSX compiler not found. Run: ./tools/download-toolchain.sh"
              echo ""
            fi

            # Set up PATH for local tools
            export PATH="$PWD/bin:$PWD/tools:$PATH"

            # Set up Go workspace if go.work exists
            if [ -f go.work ]; then
              export GOWORK="$PWD/go.work"
            fi

            echo ""
            echo "Available tools:"
            echo "  make extract  - Extract and disassemble the binary"
            echo "  make          - Build the project"
            echo "  make diff     - Compare build to original"
            echo ""
            echo "Tool submodules (run 'git submodule update --init --recursive'):"
            echo "  tools/asm-differ      - ASM comparison"
            echo "  tools/m2c             - MIPS to C decompiler"
            echo "  tools/maspsx          - PSX assembler macros"
            echo "  tools/decomp-permuter - Code permutation testing"
            echo ""
          '';

          # Environment variables
          # Set compiler flags that work well with PSX code
          LANG = "en_US.UTF-8";
        };

        # Template for creating new PSX decomp projects
        templates.default = {
          path = ./template;
          description = "PSX Decompilation Project Template";
          welcomeText = ''
            # PSX Decompilation Project

            Your new PSX decompilation project has been created!

            ## Next steps:

            1. Initialize git submodules:
               ```
               git submodule update --init --recursive
               ```

            2. Place your game's binary in the `disks/` directory

            3. Download the PSX toolchain:
               ```
               ./tools/download-toolchain.sh
               ```

            4. Configure splat for your game:
               - Copy `config/splat.example.yaml` to `config/splat.game.yaml`
               - Update paths, SHA1, and segment definitions

            5. Enter the development shell:
               ```
               nix develop
               ```

            6. Extract the binary:
               ```
               make extract
               ```

            7. Start decompiling!
          '';
        };
      }
    ) // {
      # Make templates available at the flake level
      templates.default = {
        path = ./template;
        description = "PSX Decompilation Project Template";
      };
    };
}
