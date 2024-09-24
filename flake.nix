{
  inputs = {
    configuration = {
      url = "github:ivandimitrov8080/configuration.nix";
    };
  };

  outputs = { configuration, ... }:
    let
      system = "x86_64-linux";
      pkgs = import configuration.inputs.nixpkgs {
        inherit system;
        overlays = [
          configuration.overlays.default
        ];
      };
      buildInputs = with pkgs; [
        coreutils-full
        nodejs
        (nvim.extend {
          plugins = {
            lsp.servers = {
              html.enable = true;
              ts-ls.enable = true;
              jsonls.enable = true;
              tailwindcss.enable = true;
              cssls.enable = true;
            };
          };
        })
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
