{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs { inherit system; };
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
        api = pkgs.rustPlatform.buildRustPackage rec {
          nativeBuildInputs = with pkgs; [
            pkg-config
            makeBinaryWrapper
          ];
          buildInputs = [ pkgs.openssl ];
          pname = "api";
          version = "0.0.2";
          env = {
            ROCKET_ENV = "release";
          };
          src = ./api;
          postInstall = ''
            mkdir -p $out/etc
            cp ./Rocket.toml $out/etc
            wrapProgram $out/bin/${pname} \
              --prefix ROCKET_CONFIG : $out/etc/Rocket.toml
          '';
          cargoLock = {
            lockFile = ./api/Cargo.lock;
          };
        };
      };
      nixosModules = {
        default =
          { lib, config, ... }:
          let
            inherit (lib) mkIf mkEnableOption;
            cfg = config.webshite;
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
          };
      };
    in
    {
      nixosModules = nixosModules;
      packages.${system} = packages;
    };
}
