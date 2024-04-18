{
  description = ''
    NextJS flake
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ide = {
      url = "github:ivandimitrov8080/flake-ide";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ide, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
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
      packages.${system}.default = pkgs.buildNpmPackage rec {
        buildInputs = with pkgs; [ nodejs_20 ];
        pname = "idimitrov.dev";
        version = "0.0.1";
        src = ./.;
        npmDepsHash = "sha256-JcCM8EygjCKq5qDA2g+Oe8wpm2kYH3x1DSp712I/d08=";
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

