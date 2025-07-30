## Nix Configuration System

- This is my nix configuration system. Whenever you need to introduce update to my config, remember to check the current config.
- When you are going to introduce any update, do it on a experimental branch (use 'nightly'), and commit and push to that branch after you perform `hms` to at least check the home-manager switch can pass. Never work on the master branch which I will perform merge manually.
- After you introduce updates, remember to reflect those updates in the readme, should they bring any changes.

## Testing Considerations

- When you perform testing, remember you are in a non-interactive shell so things work for me might not work for your testing, unless you take your special testing environment into consideration
