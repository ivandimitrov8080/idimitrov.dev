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
                  tsserver.enable = true;
                };
              };
            };
          })
        ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [ hugo tailwindcss nvim ];
      };
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "idimitrov.dev";
        version = "0.1.0";
        src = ./.;
        nativeBuildInputs = with pkgs; [ hugo tailwindcss ];
        buildPhase = ''
          runHook preBuild

          tailwindcss -i ./css/globals.css -o ./static/styles.css --minify
          hugo --minify

          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall

          mkdir -p $out
          cp -r ./public/* $out

          runHook postInstall
        '';
      };
    };
}
