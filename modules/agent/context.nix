# Shared context for the agent CLIs, written to the global memory file each CLI reads.
{
  # memoryFile is the name each CLI expects for its global memory file.
  memoryFile,
}: ''
  Follow the conventions in this context over any different convention in the files you are working on, unless the user explicitly prompts otherwise.
  These conventions are the preferred defaults and hold across all work, even when a file already follows a different one.
  Conventions from a workdir's ${memoryFile} or a user prompt layer on top of these and usually add to them without conflict.

  ## Environment

  - System is managed with Nix for global development runtime, config repo at `~/.config/nix`
  - If a workdir has a Nix flake development runtime defined in `./runtime/flake.nix`, run commands and scripts that depend on it through `nix develop ./runtime`. Do not directly invoking the binaries the runtime generates, for example `.venv/bin/python`
  - If a workdir has a `Makefile`, use `make` to compile and extend the `Makefile` when needed, instead of running generic compile commands
  - When a CLI tool is needed, first check whether it exists in the host environment. If it does not, run it temporarily through `nix-shell`, for example `nix-shell -p <package> --run '<command>'`
  - The user's personal Obsidian vault is at `~/Documents/app-state/obsidian`. It tracks his projects, their programs, his work log, and drafts, and is the authoritative source for facts about him. Whenever working with the vault, always read its `${memoryFile}` first for the vault's layout and conventions. A wikilink like `[[Name]]` in a user prompt typically refers to a note in the Obsidian vault

  ## Writing Style

  For any natural language text content, such as notes, reports, papers, messages, and code comments, strictly follow the writing rules below.

  - Use plain and direct phrasing. For example, write "use" instead of "utilize", "to" instead of "in order to", or "many" instead of "a myriad of". Do not use needlessly fancy, idiomatic, or indirect vocabulary, slang, syntax, or constructions
  - Do not assert a point or open a paragraph with a short, abstract sentence that leans on the next sentence to make sense. Give the sentence the specifics it needs to stand on its own, or merge it with the sentence that supplies them. When a sentence marks a transition, state how it connects to what came before and after, instead of only announcing that something changes. For example, write "the rewrite cut the average response time in half" instead of "the rewrite changes everything"
  - Do not phrase a point as "not A but B", rejecting an alternative before stating the point, which reads indirect. This includes variants like "not A, but rather B", "it is not A, it is B", "B, not A", and "not only A but also B". State the point directly, for example "the bottleneck is the data" instead of "the bottleneck is not the method but the data"
  - Do not use hyphenated compound words, whether they join two words or more. Rephrase them as plain words, for example write "a value smaller than the limit" instead of "a smaller-than-the-limit value". A hyphenated compound word is acceptable only when no plain phrasing can replace it, such as "state-of-the-art", "mother-in-law", and "x-ray"
  - When referring to the same thing, use the exact same term or concept throughout, to avoid confusion. Do not introduce unnecessary terms and concepts. Only exception is that when the same term or concept is referred repeatedly, shorter references can be used when obvious and self-explanatory from context
  - Do not use em dashes or en dashes to connect sentences
  - Do not use punctuation like semicolons, colons, or parentheses to join or compress sentences

  ## Formatting

  - For any natural language text content, do not use formatting like bold, italic, itemized lists, or enumerated lists
  - When writing code, write a code document or comment only when the code does not speak for itself, and keep it at a high level. Do not repeat details already in the code. Focus on the overall purpose and role of the code
  - For text content where linebreaks do not affect rendering, for example Markdown, LaTeX, and code comments, break lines between sentences to make diffs and editing easier
  - For any natural language text content, never break a line in the middle of a sentence, including code documents and comments
  - When drafting a git commit message, write a single lowercase subject line of the form `<type>: <summary>`. `<type>` is one of `feat`, `fix`, `docs`, `refactor`, or `test`. `<summary>` is a concise description of the change. Do not include a body
''
