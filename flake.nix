{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
  outputs =
    inputs@{
      nixpkgs,
      systems,
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
          inherit (pkgs) elmPackages stdenv writers;
          # to update -> elm2nix --help
          fetchElmDeps = elmPackages.fetchElmDeps {
            elmPackages = import ./elm-srcs.nix;
            elmVersion = elmPackages.elm.version;
            registryDat = ./registry.dat;
          };
        in
        {
          default = stdenv.mkDerivation {
            name = "idimitrov.dev";
            version = "1.0";
            src = ./.;
            # The deployment artifact uses the package set pinned by nixpkgs:
            # a Nix build has no network, so cabal cannot resolve dependencies
            # from Hackage inside the sandbox. Keep this list in sync with the
            # imports of site.hs and the `executable site` stanza of
            # idimitrov-dev.cabal.
            nativeBuildInputs = [
              (pkgs.ghc.withPackages (
                p: with p; [
                  blaze-html
                  hakyll
                  pandoc
                  skylighting
                  temporary
                  unicode-data
                ]
              ))
              elmPackages.elm
            ];
            env = pkgs.lib.optionalAttrs stdenv.hostPlatform.isLinux {
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
              cp -r _site/. $out/

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
          pkgs = mkPkgs system;
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                devenv.root = "/home/ivand/src/idimitrov.dev";
                languages = {
                  # Dependencies are resolved by cabal from Hackage (see
                  # cabal.project), so the shell only needs a plain GHC.
                  haskell = {
                    enable = true;
                    lsp.enable = true;
                    cabal.enable = true;
                    stack.enable = false;
                  };
                  elm.enable = true;
                  nix.enable = true;
                };
                packages = with pkgs; [
                  browser-sync
                  elm2nix
                  elmPackages.elm
                  elmPackages.elm-format
                  elmPackages.elm-json
                  hurl
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
                              cabal run -v0 site -- clean
                              process-compose process restart site
                            }
                            if ($path | str contains "Server.hs") {
                              devenv tasks run build:library --mode before
                            }
                            if ($path | str contains "elm.json") {
                              elm2nix convert | nixfmt -f elm-srcs.nix | save -f elm-srcs.nix
                              elm2nix snapshot
                            }
                          }
                        '';
                  in
                  {
                    site.exec = "cabal run -v0 site -- watch --no-server";
                    server = {
                      exec = "cabal run -v0 server";
                      ready = {
                        http.get = {
                          port = 1337;
                          path = "/";
                        };
                        period = 30;
                        timeout = 1;
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
                  # Resolve the newest Hackage versions allowed by the
                  # `index-state` in cabal.project (writes ~/.cabal, not the
                  # repository).
                  "cabal:update" = {
                    exec = "cabal update";
                  };
                  "clean:site" = {
                    exec = "rm -rf _site _cache dist-newstyle";
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
                      mkdir -p _cache/{tmp,site,server,generators}
                    '';
                    before = [ "build:haskell" ];
                  };
                  # One command builds the library and all three executables
                  # (site, server, gen) that used to be three `ghc`
                  # invocations.
                  "build:haskell" = {
                    exec = "cabal build all";
                    before = [
                      "build:frontend"
                      "build:library"
                      "devenv:processes:server"
                    ];
                  };
                  "build:library" = {
                    exec = ''
                      cabal run -v0 gen
                      elm-format --yes src/Generated/Api.elm
                    '';
                    after = [ "build:haskell" ];
                    before = [ "build:frontend" ];
                  };
                  "build:frontend" = {
                    exec = "cabal run -v0 site -- build";
                    after = [
                      "build:haskell"
                      "build:library"
                    ];
                    before = [ "devenv:processes:site" ];
                  };
                  "build:all" = {
                    exec = "cabal build all";
                    after = [
                      "build:frontend"
                      "build:init"
                    ];
                  };
                  "browsersync:reload" = {
                    exec = ''
                      browser-sync reload
                    '';
                    before = [ "devenv:processes:server" ];
                    after = [ "build:haskell" ];
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
