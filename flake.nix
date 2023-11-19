{
  description = ''
    NextJS flake
  '';

  inputs = {
    nixpkgs.url = "nixpkgs";
    ide = {
      url = "github:ivandimitrov8080/flake-ide";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ide, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      nvim = ide.nvim.${system}.standalone {
        plugins = {
          lsp.servers = {
            html.enable = true;
            tsserver.enable = true;
            jsonls.enable = true;
            tailwindcss.enable = true;
            cssls.enable = true;
            biome.enable = true;
          };
        };
      };
      buildInputs = with pkgs; [
        coreutils-full
        nodejs_20
        bun
        nvim
      ];
      tmuxConfig = ''
        tmux new-session -s my_session -d
        tmux new-window -t my_session:1
        tmux new-window -t my_session:2
        tmux new-window -t my_session:3
        tmux send-keys -t my_session:1.0 'nvim' C-m
        tmux send-keys -t my_session:3.0 'bun run dev' C-m
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

