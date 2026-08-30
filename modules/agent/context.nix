# Shared context for the agent CLIs, written to the global memory file each CLI reads.
{
  # memoryFile is the name each CLI expects for its global memory file.
  memoryFile,
  additionalContext ? "",
}: ''
  Follow the conventions in this context over any different convention in the files you are working on, unless the user explicitly prompts otherwise.
  These conventions are the preferred defaults and hold across all work, even when a file already follows a different one.
  Conventions from a workdir's ${memoryFile} or a user prompt layer on top of these and usually add to them without conflict.

  ## Environment

  - System is managed with Nix for global development runtime, config repo at `~/.config/nix`
  - If a workdir has a Nix flake development runtime defined in `./runtime/flake.nix`, run commands and scripts that depend on it through `nix develop ./runtime`. Do not directly invoke the binaries the runtime generates, for example `.venv/bin/python`
  - If a workdir has a `Makefile`, use `make` to compile and extend the `Makefile` when needed, instead of running generic compile commands
  - When a CLI tool is needed, first check whether it exists in the host environment. If it does not, run it temporarily through `nix-shell`, for example `nix-shell -p <package> --run '<command>'`
  - The user's Obsidian vault is at `~/Documents/Obsidian`. It tracks his projects, his work log, and drafts
    - Whenever working with the vault, always read its `${memoryFile}` first for the vault's layout and conventions
    - A wikilink like `[[Name]]` in a user prompt typically refers to a note in the vault

  ## Writing Style

  For any natural language text content (notes, reports, papers, messages, code comments, etc.), write plainly, clearly, and directly.
  More specifically, follow the rules:

  - Use plain and direct wording and sentence structure, for example write "use" instead of "utilize", "to" instead of "in order to", "many" instead of "a myriad of", and "start" instead of "kick off". Do not use needlessly fancy or indirect wording, idioms, or slang
  - Do not state a point or open a paragraph with a short, abstract sentence that depends on the next sentence to make sense. Put the missing specifics in that sentence, or merge it with the next one. A transition sentence should state how the point connects to what came before and after, instead of only announcing that something changed. For example, write "the rewrite cut the average response time in half" instead of "the rewrite changes everything"
  - Do not state a point by first rejecting an alternative. This is the "not A but B" pattern, with variants such as "not A, but rather B", "it is not A, it is B", "B, not A", and "not only A but also B". State the point directly, for example write "the bottleneck is the data" instead of "the bottleneck is not the method but the data"
  - Refer to a thing by the same term every time, and do not give it a second term, for example keep writing "the database" instead of switching to "the store" or "the backend". A shorter form is fine after the full term has appeared and context leaves no doubt, for example "the database" for "the user database"

  ## Formatting

  - Do not use em dashes or en dashes to connect sentences
  - Code document or comment should only be used when the code does not speak for itself. Do not repeat details already in the code
    - Code document should be high level, i.e., focus on the overall purpose and role of the code
  - For text content where linebreaks do not affect rendering (Markdown, LaTeX, code comments, etc.), break lines between sentences
    - Never break a line in the middle of a sentence
''
+ additionalContext
