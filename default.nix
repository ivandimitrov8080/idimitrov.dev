{ inputs, moduleWithSystem, ... }:
{
  systems = [ "x86_64-linux" ];
  perSystem =
    { system, pkgs, ... }:
    {
      config = {
        _module.args = {
          pkgs = import inputs.nixpkgs {
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
            hurl
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
                    installCargo = false;
                    installRustc = false;
                  };
                };
                rustaceanvim = {
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
            nodejs = pkgs.nodejs_22;
            src = ./.;
            npmDepsHash = "sha256-FuJoTmqwolzWuUK5lrh8Z1LYfU/RxKk+hlHGCGgbPbE=";
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
            version = "0.0.2";
            env = {
              ROCKET_ENV = "prod";
            };
            src = ./api;
            cargoLock = {
              lockFile = ./api/Cargo.lock;
            };
          };
        };
      };
    };
  flake.nixosModules.default = moduleWithSystem (
    { config, ... }:
    perSystem@{ lib, ... }:
    let
      inherit (lib) mkIf mkMerge mkEnableOption;
      cfg = perSystem.config.webshite;
      packages = config.packages;
    in
    {
      options.webshite = {
        enable = mkEnableOption "enable webshite config";
      };
      config = mkIf cfg.enable {
        services.nginx.virtualHosts =
          let
            extensions = [
              "html"
              "txt"
              "png"
              "jpg"
              "jpeg"
            ];
            serveStatic = exts: ''
              try_files ${lib.strings.concatStringsSep " " (builtins.map (x: "$uri.${x}") exts)} $uri $uri/ =404;
            '';
            webshiteConfig = {
              enableACME = true;
              forceSSL = true;
              locations = {
                "/" = {
                  root = "${packages.default}";
                  extraConfig = serveStatic extensions;
                };
                "/api" = {
                  proxyPass = "http://127.0.0.1:8000";
                };
              };
              extraConfig = ''
                add_header 'Referrer-Policy' 'origin-when-cross-origin';
                add_header X-Content-Type-Options nosniff;
              '';
            };
          in
          {
            "idimitrov.dev" = webshiteConfig;
            "www.idimitrov.dev" = webshiteConfig;
          };
        systemd.services.webshiteApi = {
          enable = true;
          serviceConfig = {
            ExecStart = "${packages.api}/bin/api";
            Restart = "always";
          };
          wantedBy = [ "multi-user.target" ];
        };
      };
    }
  );
}
