{
  inputs.configuration.url = "github:ivandimitrov8080/configuration.nix";
  outputs = { configuration, ... }:
    let
      system = "x86_64-linux";
      pkgs = import configuration.inputs.nixpkgs {
        inherit system;
        overlays = [
          configuration.overlays.default
        ];
      };
      nativeBuildInputs = with pkgs; [ pkg-config openssl ];
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          coreutils-full
          nodejs
          nodePackages_latest.prettier
          rustc
          rust-analyzer
          rustfmt
          cargo
          (nvim.extend {
            plugins = {
              lsp.servers = {
                html.enable = true;
                ts-ls.enable = true;
                jsonls.enable = true;
                tailwindcss.enable = true;
                cssls.enable = true;
                rust-analyzer = {
                  enable = true;
                  installCargo = false;
                  installRustc = false;
                };
              };
              rust-tools = {
                enable = true;
              };
            };
          })
        ] ++ nativeBuildInputs;
      };
      packages.${system} = {
        default = pkgs.buildNpmPackage {
          pname = "idimitrov.dev";
          version = "0.1.1";
          src = ./.;
          npmDepsHash = "sha256-3sED1d3WY8tUUE5KvJ3vS+AZ5xZZypP8hTSazPFH194=";
          postInstall = ''
            rm -rf $out/lib
            cp -r ./out/* $out/
          '';
        };
        api = pkgs.rustPlatform.buildRustPackage {
          inherit nativeBuildInputs;
          buildInputs = nativeBuildInputs;
          pname = "backend";
          version = "0.0.1";
          src = ./backend;
          cargoLock = {
            lockFile = ./backend/Cargo.lock;
          };
        };
      };
    };
}
