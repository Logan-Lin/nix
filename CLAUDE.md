## Nix Configuration System

- This is my nix configuration system. Whenever you need to introduce update to my config, remember to check the current config.
- After you introduce updates to the nix config, use `hms` to at least check the home-manager switch can pass.
- After you introduce updates, remember to reflect those updates in the readme, should they bring any changes.

## Testing Considerations

- When you perform testing, remember you are in a non-interactive shell so things work for me might not work for your testing, unless you take your special testing environment into consideration
- When performing hms test run, remember newly created files need to be `git add` to be recognized by nix