{
  description = ''
    NextJS flake
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    ide = {
      url = "git+ssh://git@github.com/ivandimitrov8080/xin-ide";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ide, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      nvim = ide.nvim.${system} {
        plugins = {
          lsp.servers = {
            html.enable = true;
            tsserver.enable = true;
            jsonls.enable = true;
            tailwindcss.enable = true;
          };
          cmp-spell.enable = true;
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
        tmux send-keys -t my_session:1.0 'vi' C-m
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

