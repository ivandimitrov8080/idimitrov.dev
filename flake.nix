{
  description = ''
    Run 'nix develop' to have a dev shell that has everything this project needs.
    Run `nix build` to build this project.
    Run `nix run` to run this project.
  '';

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs, systems }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      lib = pkgs.lib;
      stdenv = pkgs.stdenv;
      pname = "idimitrov-dev";
      version = "0.1.0";
      src = ./.;
      buildInputs = with pkgs; [
        coreutils-full
        (pkgs.buildEnv { name = "moe"; paths = [ ./. ]; })
      ];
      envVarsToStr = vars: lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: value: "export ${name}=\"${value}\"") vars
      );
      environment = {
        title = "Ivan Dimitrov";
        description = "Software Developer";
        github = "https://github.com/ivandimitrov8080";
        gitlab = "https://gitlab.com/ivandimitrov8080";
      };
      environmentString = envVarsToStr environment;
    in
    {
      devShell.${system} = pkgs.mkShell {
        inherit buildInputs;
      };
      packages.${system}.default = pkgs.stdenv.mkDerivation rec {
        inherit buildInputs pname version src;
        buildPhase = ''
          mkdir -p $out
          ${environmentString}
          . ./lib/mo
          for f in ./src/*.html; do mo "$f" > $out/$(basename $f) ; done
        '';
      };
      nixosModules.default = { config, pkgs, ... }:
        let cfg = config.website; in
        {
          options = {
            website = {
              enable = lib.mkEnableOption "website";
            };
          };

          config = lib.mkIf cfg.enable {
            services = {
              nginx = {
                recommendedGzipSettings = true;
                recommendedOptimisation = true;
                recommendedProxySettings = true;
                recommendedTlsSettings = true;
                sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
                appendHttpConfig = ''
                  # Add HSTS header with preloading to HTTPS requests.
                  # Adding this header to HTTP requests is discouraged
                  map $scheme $hsts_header {
                      https   "max-age=31536000; includeSubdomains; preload";
                  }
                  add_header Strict-Transport-Security $hsts_header;

                  # Enable CSP for your services.
                  #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

                  # Minimize information leaked to other domains
                  add_header 'Referrer-Policy' 'origin-when-cross-origin';

                  # Disable embedding as a frame
                  add_header X-Frame-Options DENY;

                  # Prevent injection of code in other mime types (XSS Attacks)
                  add_header X-Content-Type-Options nosniff;

                  # This might create errors
                  proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
                '';
                virtualHosts =
                  let
                    base = locations: {
                      inherit locations;

                      forceSSL = true;
                      enableACME = true;
                    };
                    proxy = port: base {
                      "/".proxyPass = "http://127.0.0.1:" + toString (port) + "/";
                    };
                    static = base {
                      root = self.packages.${system}.default;
                    };
                  in
                  {
                    "idimitrov.dev" = static // { default = true; };
                  };
              };
            };
            networking.firewall = {
              enable = true;
              allowedTCPPorts = [ 80 443 ];
            };
          };
        };
    };
}

