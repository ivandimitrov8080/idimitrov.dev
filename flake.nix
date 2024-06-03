{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
            nvim = ide.nvim.${system}.standalone {
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
        nodejs_20
        bun
        nvim
      ];
    in
    {
      devShell.${system} = pkgs.mkShell {
        inherit buildInputs;
      };
      packages.${system}.default = pkgs.buildNpmPackage {
        buildInputs = with pkgs; [ nodejs_20 ];
        pname = "idimitrov.dev";
        version = "0.0.1";
        src = ./.;
        npmDepsHash = "sha256-vYksYHkjuVeqOD4BwS18nygod/2H6Be2Cia3/p6Psek=";
        postInstall = ''
          mkdir -p $out/bin/
          cp -r ./.next/standalone/* $out/
          cp -r ./.next/standalone/.* $out/
          cp -r ./.next/static $out/.next/
          cp -r ./public $out/
          rm -rf $out/lib
          echo "${pkgs.nodejs_20}/bin/node $out/server.js" > $out/bin/$pname
          chmod +x $out/bin/$pname
        '';
      };
    };
}
