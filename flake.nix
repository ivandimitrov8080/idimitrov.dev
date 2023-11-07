{
  description = ''
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      buildInputs = with pkgs; [
        coreutils-full
        nodejs_20
        nodePackages_latest.npm-check-updates
        bun
      ];
      tmuxConfig = ''
        tmux new-session -s my_session -d
        tmux new-window -t my_session:1
        tmux new-window -t my_session:2
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
    };
}

