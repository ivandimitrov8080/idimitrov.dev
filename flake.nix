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
                  ts-ls.enable = true;
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
        npmDepsHash = "sha256-3sED1d3WY8tUUE5KvJ3vS+AZ5xZZypP8hTSazPFH194=";
        postInstall = ''
          rm -rf $out/lib
          cp -r ./out/* $out/
        '';
      };
    };
}
