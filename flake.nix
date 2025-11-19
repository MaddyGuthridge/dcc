{
  description = "DCC - The Debugging C/C++ Compiler";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs allSystems (
          system:
          f {
            system = system;
            pkgs = import nixpkgs { inherit system; };
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs, ... }:
        {
          # dcc
          default =
            let
              binName = "dcc";
              cDependencies = with pkgs; [
                gcc
                clang
                python3
                gdb
                valgrind
                gnumake
                git
                zip
                which
              ];
            in
            pkgs.stdenv.mkDerivation {
              name = binName;
              src = self;
              buildInputs = cDependencies;
              # nativeBuildInputs = [ pkgs.makeWrapper ];
              buildPhase = "make";
              installPhase = ''
                mkdir -p $out/bin
                cp ${binName} $out/bin/${binName}
                # Also copy across gdb so that it is avaiable after installation
                cp "$(which gdb)" $out/bin/gdb
              '';
            };
          # gdb required as a runtime dependency for all programs built with dcc
          gdb = pkgs.gdb;
        }
      );

      devShells = forAllSystems (
        { system, pkgs }:
        {
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.default
              pkgs.gdb
            ];
          };
        }
      );
    };
}
