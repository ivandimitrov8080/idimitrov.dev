---
title: Describe your Nix/NixOS experience
date: 2026-10-27
author: Ivan Dimitrov
description: Describing my usage of NixOS. Why, how and when I decided to delve into the purely functional declarative linux configuration and deployment.
---

When I was working in the UK, I was interested in linux distros and
was exploring arch linux with KDE plasmafor my personal computing.
Right around that time the Steam deck got released.
They also chose the same distro setup for their product. My
colleagues were interested in the deck and it's success so they tasked
me with providing a development environment for the team. I had already
broken a few arch installs trying to create a custom ISO to put on my
flash drive so I knew arch isn't the best choice for creating that. Then
things changed for me and I had to move, but I kept thinking about the
problem out of curiosity. Then I found nix.

I read the documentation and the paper for a few months before finally
deciding to go all in and install nixos on my laptop.=20
When I started the experiment it was very difficult to get anything
done.
It did so many things differently from what I already knew.
I had to relearn how to think about systems, state, files, configuration,
environment and more things in the details around defining such things.
In the first year everything was very forced. I was questioning my decision=
 to
use nix constantly, but I knew the problem isn't the software, because
with enough effort it did what I wanted it to do and it did it
well. As time passed I started to become more and more fluent in that
way of thinking to the point that normal configuration management makes
no sense to me anymore. I can't see myself using anything other than nixos
for my computing needs. Also I can't seem to be able to replace my
current configuration with anything else like guix either as it grew
considerably and became integral to my everyday computing.

I forced myself to declare every and all configuration using nix.
First it was a usable system. Just sway with a terminal, neovim and a
browser. Then a mailserver, wireguard tunnel and a deployment target for
my website. Then common configured shell utilities for both the
server and the laptop. Everything I use goes straight to my
configuration repository. Watching a movie with mpv and I want to resume
playback from when I last stopped? There's an option for that - straight
to nix. Development environments with all the tooling needed to build
and develop and deploy the project in question? There's tooling for that
- straight to nix. Want to make my graphical environment look like it's
from a hacker movie? That's right. There's nix tooling for that -
straight into my repo it goes.

Everything I do on a computer can be found in these two repositories:
https://github.com/ivandimitrov8080/configuration.nix
https://github.com/ivandimitrov8080/hosts.nix
(except per-project development environments - those are in their own repos)

I also contributed to nixpkgs, home-manager and nixvim.
