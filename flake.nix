{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ide = {
      url = "github:ivandimitrov8080/flake-ide";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ide, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            nvim = ide.nvim.${system}.standalone.default {
              plugins = {
                lsp.servers = {
                  html.enable = true;
                  tsserver.enable = true;
                  jsonls.enable = true;
                  tailwindcss.enable = true;
                  cssls.enable = true;
                };
              };
            };
          })
        ];
      };
      buildInputs = with pkgs; [
        coreutils-full
        nodejs
        nvim
        nodePackages_latest.prettier
      ];
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        inherit buildInputs;
      };
      packages.${system}.default = pkgs.buildNpmPackage {
        pname = "idimitrov.dev";
        version = "0.1.1";
        src = ./.;
        npmDepsHash = "sha256-+GgP+cilcphMZxns/EM2TTRDuQi8RE1PkxsDG3gXZEQ=";
        postInstall = ''
          rm -rf $out/lib
          cp -r ./out/* $out/
        '';
      };
    };
}
