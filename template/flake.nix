# Nix Flake for PSX Decompilation
# ================================
# This flake inherits from the nix-decomp-psx template.
# It provides a development environment for your specific game.

{
  description = "My PSX Game Decompilation Project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          pycparser
          pillow
          toml
          pyyaml
          intervaltree
          watchdog
          levenshtein
          cxxfilt
          tabulate
          requests
          graphviz
          black
          pip
          virtualenv
        ]);

      in
      {
        devShells.default = pkgs.mkShell {
          name = "psx-decomp";

          buildInputs = with pkgs; [
            # Core build tools
            gnumake
            ninja
            cmake
            pkg-config

            # MIPS cross-compilation
            pkgsCross.mipsel-linux-gnu.buildPackages.binutils
            pkgsCross.mipsel-linux-gnu.buildPackages.gcc

            # Python
            pythonEnv

            # Utilities
            git
            curl
            wget
            unzip
            p7zip
            clang-tools
            rustc
            cargo
            go
            bchunk
            libelf
            coreutils
            gawk
            gnused
            gnugrep
            findutils
            file
            which
            iconv

            # TODO: dosemu2 - Required for some PSY-Q DOS tools
            # Not available in nixpkgs. See README for workarounds.
          ];

          shellHook = ''
            echo "🎮 PSX Decompilation Environment"
            echo "================================"

            if [ ! -d .venv ]; then
              python -m venv .venv
            fi
            source .venv/bin/activate

            if [ -f tools/requirements-python.txt ]; then
              pip install -q -r tools/requirements-python.txt
            fi

            mkdir -p bin
            export PATH="$PWD/bin:$PWD/tools:$PATH"

            if [ -f go.work ]; then
              export GOWORK="$PWD/go.work"
            fi

            if [ ! -f bin/cc1-psx-26 ]; then
              echo ""
              echo "⚠️  Run: ./tools/download-toolchain.sh"
            fi
            echo ""
          '';

          LANG = "en_US.UTF-8";
        };
      }
    );
}
