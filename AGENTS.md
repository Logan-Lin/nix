# Yan Lin's Nix Configuration

Flake-based configuration for NixOS, nix-darwin, and home-manager, covering several personal machines across Linux and macOS.

See `README.md` for an overview of the repository structure and the commands to rebuild a system, apply home-manager, run garbage collection, and bootstrap a new machine.

## Continuous integration

Every push evaluates all system and home configurations for both platforms, so a change that fails to evaluate is caught before it lands.
A weekly job updates the flake inputs, rebuilds every configuration against the update, and opens a pull request only when the rebuild succeeds.

Avoid running the heavy evaluation or rebuild of every configuration yourself, since the CI already does this on every push.
Leave that work to the CI and rely on it to catch a change that fails to evaluate.

## Conventions

This repository is public and has no secret-management layer, so never commit real credentials or private keys.
