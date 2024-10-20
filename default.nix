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
          rustc
          rust-analyzer
          rustfmt
          cargo
          pkg-config
          openssl
          (nvim.extend {
            plugins = {
              lsp.servers = {
                svelte.enable = true;
                html.enable = true;
                ts_ls.enable = true;
                jsonls.enable = true;
                tailwindcss.enable = true;
                cssls.enable = true;
                rust_analyzer = {
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
        ];
      };
      packages = {
        default = pkgs.buildNpmPackage {
          pname = "idimitrov.dev";
          version = "0.1.1";
          src = ./.;
          npmDepsHash = "sha256-5dBbBF16aUTEda3aGVpeLE/LF75b/Pay9AF12Ip1cRo=";
          npmFlags = [ "--legacy-peer-deps" ];
          postInstall = ''
            rm -rf $out/*
            rm -rf $out/.*
            cp -r ./build/* $out/
          '';
        };
        api = pkgs.rustPlatform.buildRustPackage {
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
          pname = "api";
          version = "0.0.1";
          src = ./api;
          cargoLock = {
            lockFile = ./api/Cargo.lock;
          };
        };
      };
    };
  };
}
