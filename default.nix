{ inputs, ... }: {
  systems = [ "x86_64-linux" ];
  perSystem = { system, pkgs, ... }: {
    config = {
      _module.args = {
        pkgs = import inputs.configuration.inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.configuration.overlays.default
          ];
        };
      };
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          coreutils-full
          nodejs
          nodePackages_latest.prettier
          (nvim.extend {
            plugins = {
              lsp.servers = {
                svelte.enable = true;
                html.enable = true;
                ts-ls.enable = true;
                jsonls.enable = true;
                tailwindcss.enable = true;
                cssls.enable = true;
              };
            };
          })
        ];
      };
      packages.default = pkgs.buildNpmPackage {
        pname = "idimitrov.dev";
        version = "0.1.1";
        src = ./.;
        npmDepsHash = "sha256-a7B1g+yNj/m0ILsGe+TbqptQD6qp0kFZQmXLw+rrtwo=";
        postInstall = ''
          rm -rf $out/*
          rm -rf $out/.*
          cp -r ./build/* $out/
        '';
      };
    };
  };
}
