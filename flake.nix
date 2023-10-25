{
  description = ''
    Run 'nix develop' to have a dev shell that has everything this project needs.
    Run `nix build` to build this project.
    Run `nix run` to run this project.
  '';

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      lib = pkgs.lib;
      stdenv = pkgs.stdenv;
      pname = "idimitrov-dev";
      version = "1.0.0";
      src = ./.;
      buildInputs = with pkgs; [
        coreutils-full
      ];
      getPartial = name: builtins.readFile ./src/partials/${name}.html;
      env = {
        title = "Ivan Dimitrov";
        description = "Software Developer";
        intro = "yo";
        head = getPartial "head";
        githubSvg = getPartial "svg/github-svg";
        gitlabSvg = getPartial "svg/gitlab-svg";
        githubUrl = "https://github.com/ivandimitrov8080";
        gitlabUrl = "https://gitlab.com/ivandimitrov8080";
      };
      tmuxConfig = ''
        tmux new-session -s my_session -d
        tmux new-window -t my_session:1
        tmux new-window -t my_session:2
        tmux split-window -h -t my_session:2
        tmux send-keys -t my_session:1.0 'vi' C-m
        tmux attach-session -t my_session
      '';
    in
    {
      devShell.${system} = pkgs.mkShell {
        inherit buildInputs;
        shellHook = ''
          ${tmuxConfig} 
        '';
      };
      packages.${system}.default = pkgs.stdenv.mkDerivation rec {
        inherit buildInputs pname version src env;
        buildPhase = ''
          mkdir -p $out
          . ./lib/mo
          f="./src/index.html"
          head=$(echo "$head" | mo)
          mo "$f" > $out/$(basename $f);
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
                virtualHosts = {
                  "idimitrov.dev" = {
                    forceSSL = true;
                    enableACME = true;
                    root = self.packages.${system}.default;
                    default = true;
                  };
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

