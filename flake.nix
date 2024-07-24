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
      ];
    in
    {
      devShell.${system} = pkgs.mkShell {
        inherit buildInputs;
      };
      packages.${system}.default = pkgs.buildNpmPackage rec {
        pname = "idimitrov.dev";
        version = "0.0.1";
        src = ./.;
        npmDepsHash = "sha256-+GgP+cilcphMZxns/EM2TTRDuQi8RE1PkxsDG3gXZEQ=";
        postInstall = ''
          mkdir -p $out/bin/
          cp -r ./.next/standalone/* $out/
          cp -r ./.next/standalone/.* $out/
          cp -r ./.next/static $out/.next/
          cp -r ./public $out/
          rm -rf $out/lib

          makeWrapper ${pkgs.lib.getExe pkgs.nodejs} $out/bin/${pname} \
            --add-flags $out/server.js \
        '';
      };
    };
}
