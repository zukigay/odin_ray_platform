# let
#   # nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.11";
#   import <nixpkgs> {};
#   pkgs = import nixpkgs { config = {}; overlays = []; };
# in
with import <nixpkgs> {};

pkgs.mkShell {
  stdenv = pkgs.clangStdenv;
  packages = with pkgs; [
    # rustup
    glfw
    cmake
    clang
    wayland
  ];
  nativeBuildInputs = [
    pkgs.libGL

    # Web support (uncomment to enable)
    # pkgs.emscripten
  ];

  LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
    libGL
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xorg.libXi
    xorg.libX11
  ];
  shellHook = ''
  alias o="odin run ."
  '';
  LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
}
