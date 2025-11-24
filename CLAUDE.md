## Coding Style
- Never write shebang unless specifically requested
- Do not abuse comments when writing code, especially code intuitive enough that does not need comments to further explain

## NixOS
- This is my nixOS configuration for all my personal computers, and you are running on one of the nixOS hosts
- Check existing nix config when interacting with runtime environments
- Per spirit of nixOS reproducibility, try to analysis problems purely based on my nixOS configuration system first, since it should be representative of the actual runtime environment of the host machine; especially avoid interacting with temporarily runtime environments, like searching in nix store or using `nix-env`.
- Use `oss` alias for nixos-rebuild switch and `hms` alias for home-manager switch
