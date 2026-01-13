{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    configuration.url = "github:ivandimitrov8080/configuration.nix";
    systems.url = "github:nix-systems/default";
    # nvim config helper
    nixvim-flake.url = "github:nix-community/nixvim";
    nixvim-flake.inputs.nixpkgs.follows = "nixpkgs";
    # neovim latest version
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
  outputs =
    inputs@{
      nixpkgs,
      configuration,
      systems,
      nixvim-flake,
      neovim-nightly-overlay,
      devenv,
      treefmt-nix,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      mkPkgs = system: import nixpkgs { inherit system; };
      nixosModules = {
        default =
          {
            system,
            lib,
            config,
            ...
          }:
          let
            inherit (lib) mkIf mkEnableOption;
            cfg = config.webshite;
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
                  root = "${packages.${system}.default}";
                  extraConfig = serveStatic extensions;
                };
              };
              extraConfig = ''
                add_header 'Referrer-Policy' 'origin-when-cross-origin';
                add_header X-Content-Type-Options nosniff;
              '';
            };
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
          { ... }:
          {
            _module.args.system = "x86_64-linux";
            imports = [ nixosModules.default ];
            networking = {
              useNetworkd = true;
              firewall = {
                allowedTCPPorts = [
                  80
                  443
                ];
                allowedUDPPorts = [
                  80
                  443
                ];
              };
            };
            systemd.network.enable = true;
            webshite.enable = true;
            services.nginx.enable = true;
            security = {
              acme = {
                defaults = {
                  server = "https://acme-staging-v02.api.letsencrypt.org/directory";
                  email = "test@example.com";
                };
                acceptTerms = true;
              };
            };
          };
      };
      nixosTest = {
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
          '';
      };
      packages = eachSystem (
        system:
        let
          pkgs = mkPkgs system;
          inherit (pkgs) stdenv;
          # to update -> elm2nix --help
          fetchElmDeps = pkgs.elmPackages.fetchElmDeps {
            elmPackages = import ./elm-srcs.nix;
            elmVersion = pkgs.elmPackages.elm.version;
            registryDat = ./registry.dat;
          };
        in
        {
          default = stdenv.mkDerivation {
            name = "idimitrov.dev";
            version = "1.0";
            src = ./.;
            nativeBuildInputs = with pkgs; [
              (ghc.withPackages (p: with p; [ hakyll ]))
              elmPackages.elm
            ];
            env = {
              LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
              LANG = "en_US.UTF-8";
            };
            postConfigure = fetchElmDeps;
            buildPhase = ''
              runHook preBuild

              runghc ./site.hs build

              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall

              mkdir -p $out/
              cp -r _site/* $out/

              runHook postInstall
            '';
          };
        }
      );
      checks = eachSystem (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          default = pkgs.testers.runNixOSTest nixosTest;
        }
      );
      devShells = eachSystem (
        system:
        let
          nixvim-default = nixvim-flake.legacyPackages.${system}.makeNixvim {
            package = neovim-nightly-overlay.packages.${system}.default;
          };
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (_final: _prev: {
                nixvim = nixvim-default;
              })
              configuration.overlays.default
            ];
          };
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                devenv.root = "/home/ivand/src/idimitrov.dev";
                packages = with pkgs; [
                  (ghc.withPackages (
                    p: with p; [
                      hakyll
                      servant
                      servant-server
                      servant-elm
                      hspec
                      http-client
                      http-types
                      wai-cors
                      persistent
                      persistent-template
                      persistent-redis
                      persistent-postgresql
                    ]
                  ))
                  haskellPackages.hakyll
                  elmPackages.elm
                  elmPackages.elm-format
                  elmPackages.elm-json
                  elm2nix
                  (nixvim.web.extend {
                    lsp.servers = {
                      elmls.enable = true;
                      hls.enable = true;
                    };
                  })
                  nodePackages.browser-sync
                  watchexec
                ];
                processes =
                  let
                    siteWatch = "bin/site watch";
                    server = "bin/server";
                    browserSync = "browser-sync start --proxy localhost:8000 --files '_site/**/*'";
                    serverWatcher = "watchexec -w server --exts hs -- process-compose process restart server";
                    syncElmDeps =
                      pkgs.writeScript "sync_elm_deps"
                        # bash
                        ''
                          elm2nix convert | ${pkgs.nixfmt}/bin/nixfmt -f elm-srcs.nix > elm-srcs.nix
                          elm2nix snapshot
                        '';
                    elm2nixWatcher =
                      # bash
                      ''
                        watchexec -f elm.json -- ${syncElmDeps}
                      '';
                  in
                  {
                    site.exec = siteWatch;
                    server.exec = server;
                    browser-sync.exec = browserSync;
                    elm-watcher.exec = elm2nixWatcher;
                    server-watcher.exec = serverWatcher;
                  };
                tasks = {
                  "clean:site" = {
                    exec = "rm -rf bin _site _cache";
                  };
                  "build:init" = {
                    exec = "mkdir -p bin/Generators";
                    before = [
                      "build:server"
                      "build:site"
                      "build:library"
                    ];
                  };
                  "build:server" = {
                    exec = "ghc -outputdir bin server/Main.hs -iserver -o bin/server && browser-sync reload";
                    before = [ "devenv:processes:server" ];
                  };
                  "build:site" = {
                    exec = "ghc -outputdir bin site.hs -o bin/site && bin/site build";
                    before = [ "devenv:processes:site" ];
                  };
                  "build:library" = {
                    exec = ''
                      ghc -outputdir bin/Generators server/Generators/Main.hs -iserver -o bin/Generators/gen
                      bin/Generators/gen
                      elm-format --yes src/Generated/Api.elm
                    '';
                    before = [
                      "build:site"
                      "build:server"
                    ];
                  };
                };
                git-hooks.hooks = {
                  nixfmt.enable = true;
                  prettier.enable = true;
                  ormolu.enable = true;
                  elm-format.enable = true;
                  deadnix.enable = true;
                  statix.enable = true;
                };
              }
            ];
          };
        }
      );
      formatter = eachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        (treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            prettier.enable = true;
            ormolu.enable = true;
            elm-format.enable = true;
            deadnix.enable = true;
            statix.enable = true;
          };
        }).config.build.wrapper
      );
    in
    {
      inherit
        checks
        devShells
        formatter
        nixosModules
        packages
        ;
    };
}
