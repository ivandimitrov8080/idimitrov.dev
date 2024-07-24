#!/usr/bin/env bash

content="---
title:
goal:
role:
date:
z: 9999
draft: true
---
"

echo "$content" > "./_content/$1.md"

