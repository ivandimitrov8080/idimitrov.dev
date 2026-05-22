{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
      packages = eachSystem (
        system:
        let
          pkgs = mkPkgs system;
          inherit (pkgs) stdenv writers;
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
              cp -r _site/.* $out/

              runHook postInstall
            '';
          };
          update = writers.writeNuBin "update" {
            makeWrapperArgs = with pkgs; [
              "--prefix"
              "PATH"
              ":"
              "${lib.makeBinPath [
                elmPackages.elm-json
                elm2nix
                nixfmt
              ]}"
            ];
          } (builtins.readFile ./update.nu);
        }
      );
      checks = eachSystem (system: packages.${system} // devShells.${system});
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
                languages = {
                  haskell = {
                    enable = true;
                    package = pkgs.ghc.withPackages (
                      p: with p; [
                        hakyll
                        servant
                        servant-server
                        servant-auth
                        servant-auth-server
                        servant-auth-swagger
                        servant-elm
                        hspec
                        http-client
                        http-types
                        wai-cors
                        hasql
                        hasql-th
                        hasql-pool
                        tuple
                        password
                        jwt
                        raw-strings-qq
                      ]
                    );
                    lsp.enable = true;
                    cabal.enable = false;
                    stack.enable = false;
                  };
                  elm.enable = true;
                  nix.enable = true;
                };
                packages = with pkgs; [
                  haskellPackages.hakyll
                  elmPackages.elm
                  elmPackages.elm-format
                  elmPackages.elm-json
                  elm2nix
                  hurl
                  (nixvim.web.extend {
                    lsp.servers = {
                      elmls.enable = true;
                      sqls.enable = true;
                    };
                    plugins = {
                      haskell-tools = {
                        enable = true;
                        enableTelescope = true;
                      };
                    };
                  })
                  browser-sync
                ];
                services = {
                  postgres = {
                    enable = true;
                    initialDatabases = [
                      {
                        name = "app";
                        pass = "app";
                        user = "app";
                        schema = ./sql/schema.sql;
                      }
                    ];
                    initialScript = builtins.readFile ./sql/initial.sql;
                  };
                };
                processes =
                  let
                    inherit (pkgs.writers) writeNu;
                    watcher =
                      writeNu "watcher"
                        # nu
                        ''
                          watch . --glob=**/*.hs {|op, path, newpath|
                            if ($path | str contains "Server.hs") {
                              process-compose process restart server
                            }
                            if ($path | str contains "site.hs") {
                              ./bin/site clean
                              process-compose process restart site
                            }
                            if ($path | str contains "Server.hs") {
                              devenv tasks run build:library --mode before
                            }
                            if ($path | str contains "elm.json") {
                              elm2nix convert | nixfmt -f elm-srcs.nix | save elm-srcs.nix -f
                              elm2nix snapshot
                            }
                          }
                        '';
                  in
                  {
                    site.exec = "bin/site watch --no-server";
                    server = {
                      exec = "bin/server";
                      ready = {
                        http.get = {
                          port = 1337;
                          path = "/";
                        };
                        period = 1;
                        timeout = 10;
                        initial_delay = 0;
                      };
                    };
                    watcher.exec = "${watcher}";
                    browser-sync = {
                      exec = "browser-sync start --proxy localhost:1337 --files '_site/**/*'";
                      after = [ "devenv:processes:server" ];
                    };
                  };
                tasks = {
                  "clean:site" = {
                    exec = "rm -rf bin _site _cache";
                  };
                  "db:clean" = {
                    exec = ''
                      psql -U app -d app -f sql/clean.sql
                    '';
                    before = [ "db:seed" ];
                  };
                  "db:seed" = {
                    exec = ''
                      psql -U app -d app -f sql/seed.sql
                    '';
                    before = [ "test:server" ];
                  };
                  "build:init" = {
                    exec = ''
                      mkdir -p bin/
                      mkdir -p _cache/{tmp,site,server,generators}
                    '';
                    before = [
                      "build:server"
                      "build:site"
                      "build:generators"
                    ];
                  };
                  "build:server" = {
                    exec = "ghc -threaded -outputdir _cache/server server/Main.hs -iserver -o bin/server";
                    before = [ "devenv:processes:server" ];
                  };
                  "build:frontend" = {
                    exec = "bin/site build";
                    after = [ "build:site" ];
                    before = [ "devenv:processes:site" ];
                  };
                  "build:site" = {
                    exec = "ghc -outputdir _cache/site site.hs -o bin/site";
                    before = [ "build:frontend" ];
                  };
                  "build:library" = {
                    exec = ''
                      bin/gen
                      elm-format --yes src/Generated/Api.elm
                    '';
                    before = [ "build:site" ];
                  };
                  "build:generators" = {
                    exec = ''
                      ghc -outputdir _cache/generators generators/Main.hs -iserver -o bin/gen
                    '';
                    before = [ "build:library" ];
                  };
                  "browsersync:reload" = {
                    exec = ''
                      browser-sync reload
                    '';
                    before = [ "devenv:processes:server" ];
                    after = [ "build:server" ];
                  };
                  "test:server" = {
                    exec = "hurl test/server/login.hurl";
                  };
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
            elm-format.enable = true;
            deadnix.enable = true;
            statix.enable = true;
            ormolu.enable = true;
            ormolu.ghcOpts = [
              "ImportQualifiedPost"
            ];
          };
        }).config.build.wrapper
      );
      templates = {
        default = {
          description = ''
            A web flake for web projects
          '';
          welcomeText = ''
            # Web
            Create maintainable, reproducible full stack web apps using purely-functional programming languages: Haskell, Elm, Nix


            ## Other tips
            For a quick license setup use license-cli:

            ```
                # SPDX is the license id like MIT or GPL-3.0
                nix shell p#license-cli --command "license text MIT"
            ```
          '';
          path = ./.;
        };
      };
    in
    {
      inherit
        checks
        devShells
        formatter
        packages
        templates
        ;
    };
}
