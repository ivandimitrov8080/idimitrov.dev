{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs { inherit system; };
      lib = pkgs.lib;
      packages = {
        default = pkgs.buildNpmPackage {
          pname = "idimitrov.dev";
          version = "0.1.1";
          nodejs = pkgs.nodejs;
          src = ./.;
          npmDepsHash = "sha256-kdtIoBTZgSFtiwL40M9/dv+miR0wSEFsO+Z0CF8N5z8=";
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
        testInteractive = test.driverInteractive;
      };
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
              services.nginx.virtualHosts = {
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
      client = {
        default =
          { pkgs, ... }:
          {
            environment.systemPackages = with pkgs; [
              curl
              gnugrep
            ];
            systemd.network.enable = true;
            networking.useNetworkd = true;
          };
      };
      server = {
        default =
          { pkgs, config, ... }:
          {
            imports = [ nixosModules.default ];
            networking.firewall.allowedTCPPorts = [
              80
              443
            ];
            networking.firewall.allowedUDPPorts = [
              80
              443
            ];
            systemd.network.enable = true;
            networking.useNetworkd = true;
            webshite.enable = true;
            services.nginx.enable = true;
            security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
            security.acme.defaults.email = "test@example.com";
            security.acme.acceptTerms = true;
          };
      };
      test = pkgs.testers.runNixOSTest {
        name = "test";
        nodes = {
          server = server.default;
          client1 = client.default;
        };
        testScript =
          #py
          ''
            start_all()
            client1.wait_for_unit("default.target")
            server.wait_for_unit("nginx.service")
            client1.succeed("curl http://server | grep -o '301'")
            client1.succeed("curl -k https://server | grep -o 'Home | idimitrov.dev'")
            client1.succeed("curl -k https://server/api | grep -o 'Rocket'")
          '';
      };
    in
    {
      nixosModules = nixosModules;
      packages.${system} = packages;
      checks.${system}.default = test;
    };
}
