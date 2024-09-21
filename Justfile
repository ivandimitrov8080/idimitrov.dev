default: all

all: build

build:
  nix build

update:
  nix flake update

