---
title: Describe your experience with low-level linux concepts
date: 2026-10-27
author: Ivan Dimitrov
description: Describing how I built a graphical linux greeter to make the boot process smooth and uniform across bootloader, plymouth and login.
---

I built a greeter for greetd that got accepted as a known greeter (ndlm).

In short https://sr.ht/~kennylevinsen/greetd/ is a login manager daemon
that uses greeters for logging into linux. It provides an SDK for
programmers to create their own login solutions. The interface that
takes in a username, password and a session can be anything. As per the
repo README:
"If you can run it from your shell in a TTY, greetd can start it.
If it can be taught to speak a simple JSON-based IPC protocol, then it
can be a greeter."

My greeter https://github.com/ivandimitrov8080/ndlm was created because
I got tired of seeing the classic linux flickering every time I booted into=
 linux.
The flickering happens, because the available graphical greeters start eith=
er an X
or a wayland session to display graphics, which is a heavy operation to
start resulting in a blank screen.
That's overkill for a simple program that has 3 inputs so I made mine
not use any graphical environment while still providing graphics using
Direct Rendering Manager. Rust's cairo bindings help abstract away the
logic behind generating the frames (image buffers that get sent to DRM).
Pango and the pangocairo library provide font support. I wrote a custom
plymouth (it's the graphical screen when booting) theme parser so that
the greeter can reuse the same colors from the boot screen.

The result is a boot process that does not display any flickering and
looks uniform across the bootloader, plymouth and the greeter as the 3
processes use the same theme colors.

I guess next steps is to figure out how to make starting wayland not
display the black flicker screen, but that's out of scope for the ndlm
greeter.
