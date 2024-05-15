{
  description = "Mucking around with zig stuff";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zls-flake = {
      url = "github:zigtools/zls";
      inputs.zig-overlay.follows = "zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zig-overlay, zls-flake }: 
  let 
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = nixpkgs.lib;
    zig = zig-overlay.packages.${system}.master;
    zls = zls-flake.packages.${system}.zls;
  in {
    packages.${system} = {
      inherit zig;
    };
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [ 
        pkg-config
        gdb
        zls

        zig
        SDL2
      ];
    };
  };
}
