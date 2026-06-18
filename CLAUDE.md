# Yan Lin's Nix Configuration

Flake-based configuration for NixOS, nix-darwin, and home-manager, covering several personal machines across Linux and macOS.

See `README.md` for an overview of the repository structure and the commands to rebuild a system, apply home-manager, run garbage collection, and bootstrap a new machine.

## Layout

`flake.nix` is the entry point.
It declares all external inputs and discovers hosts automatically by reading the directories inside each platform group under `hosts/`, so a host joins the build once its directory exists under the right platform group.
For each host it produces a system configuration and a matching home-manager configuration, and it passes the flake `inputs` through to every module.

`hosts/` holds per-machine configuration, split by platform into a Linux group and a macOS group.
`modules/` holds reusable feature modules that machines opt into.

## Configuration layering

Configuration is composed in three layers, from general to specific.
The repository root holds cross-platform defaults shared by every machine, in `hosts/{system,home}-default.nix`.
Each platform group adds `hosts/<platform>/{system,home}-default.nix`, which import the root defaults and layer on settings unique to that operating system.
Each host then defines `hosts/<platform>/<host>/{system,home}.nix`, which import the platform defaults and select the feature modules and host-specific settings the machine needs.
The system configuration and the home-manager configuration follow this pattern in parallel, with separate `system` and `home` files at every layer.
Linux hosts additionally carry their own hardware and disk-layout files next to the shared structure.

## Continuous integration

Every push evaluates all system and home configurations for both platforms, so a change that fails to evaluate is caught before it lands.
A weekly job updates the flake inputs, rebuilds every configuration against the update, and opens a pull request only when the rebuild succeeds.

## Conventions

This repository is public and has no secret-management layer, so never commit real credentials or private keys.
For any prose in commit messages or documentation, follow the writing style rules in the global context.
