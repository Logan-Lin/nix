# Shared context for the agent CLIs, written to the global memory file each CLI reads.
{
  memoryFile,
  additionalContext ? "",
}: ''
  ## Environment

  System is managed with Nix for global development runtime, config repo at `~/.config/nix`.

  - Certain CLI tools (`sed`, `grep`, `awk`, `find`, `xargs`, `make`) and the `coreutils` commands are installed through Nix and are GNU-flavored
  - If a workdir has a Nix flake development runtime defined in `./runtime/flake.nix`, run commands and scripts that depend on it through `nix develop ./runtime`. Do not directly invoke the binaries the runtime generates, for example `.venv/bin/python`
  - If a workdir has a `Makefile`, use `make` to compile and extend the `Makefile` when needed, instead of running generic compile commands
  - When a CLI tool is needed, first check whether it exists in the host environment. If it does not, run it temporarily through `nix-shell`, for example `nix-shell -p <package> --run '<command>'`

  ## Obsidian vault

  The user's Obsidian vault is at `~/Documents/Obsidian`.

  - Whenever working with the vault, always read its `${memoryFile}` first for the vault's layout and conventions
  - A wikilink like `[[Name]]` in a user prompt typically refers to a note in the vault
''
+ additionalContext
