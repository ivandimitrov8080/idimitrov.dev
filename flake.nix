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
    };
}

