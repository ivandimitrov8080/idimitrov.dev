{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
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
                  cssls.enable = true;
                  gopls.enable = true;
                  html.enable = true;
                  jsonls.enable = true;
                  tailwindcss.enable = true;
                };
              };
            };
          })
        ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [ hugo nvim ];
      };
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "idimitrov.dev";
        version = "0.1.0";
        src = ./.;
        nativeBuildInputs = with pkgs; [ hugo ];
        buildPhase = "${pkgs.hugo}/bin/hugo --minify";
        installPhase = ''
          mkdir -p $out
          cp -r ./public/* $out
        '';
      };
    };
}
