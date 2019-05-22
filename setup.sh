#!/usr/bin/env bash

command="& {./RainbowMiner.ps1 -configfile ./Config/config.txt -setuponly; exit \$lastexitcode}"

while true; do

  pwsh -ExecutionPolicy bypass -Command ${command}

  if [ "$?" != "99" ]; then
    break
  fi

done
