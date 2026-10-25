# Shared custom commands for agent command menus.
{
  proofread = ''
    ---
    description: Proofread text for grammar, spelling, and punctuation errors
    argument-hint: <file>
    ---

    ## Target

    $ARGUMENTS

    ## Task

    Proofread the target file(s). Fix only basic errors, including grammar, spelling, and punctuation errors.
  '';

  polish = ''
    ---
    description: Proofread text for basic errors and enforce writing style rules
    argument-hint: <file>
    ---

    ## Target

    $ARGUMENTS

    ## Task

    Proofread and edit the target file(s). Fix basic errors, including grammar, spelling, and punctuation errors. Also enforce the following writing style rules:

    1. Use plain and direct wording and sentence structure. Do not use needlessly fancy or indirect wording, idioms, or slang.
    2. Use the same term every time you refer to the same thing.
    3. Make the content self-contained, so a reader who sees only the content can follow it.
  '';

  fact-check = ''
    ---
    description: Check text for factual errors against reputable sources
    argument-hint: <file>
    ---

    ## Target

    $ARGUMENTS

    ## Task

    Check the target file(s) for factual errors:

    1. Identify concrete factual claims, such as names, dates, numbers, attributions, definitions, events, and technical specifications.
    2. Verify each claim against reputable and relatively recent sources. Prefer primary sources, official documentation, peer-reviewed publications, and well-established news outlets. Do not rely on a single low-quality source.
    3. Skip opinions, subjective statements, and unverifiable claims.

    For any confirmed factual error, fix it with the minimal change needed to make the claim correct.
  '';

  gtd = ''
    ---
    description: Act on Obsidian vault TODOs
    argument-hint: <[[note]]> [TODO specification]
    ---

    ## Target

    $ARGUMENTS

    ## Task

    Act on the target Obsidian vault TODOs.

    1. Use the first wikilink to identify the note or note section that contains the TODOs.
    2. Interpret the rest of the target as an optional specification that can identify one or more TODOs, such as a checkbox line or a `> [!todo]` callout.
       - If a specification is present, locate and act on the TODOs it identifies.
       - Otherwise, locate and act on every checkbox line and `> [!todo]` callout in the note or note section.

    Keep every TODO checkbox line and `> [!todo]` callout exactly intact. Do not remove them or change their status after completing the work.
  '';

  commit = ''
    ---
    description: Commit the current change with a subject line and a body
    ---

    ## Task

    Commit the current working tree change as one commit.

    1. Stage and review the change.
    2. Write a lowercase subject line of the form `<type>: <summary>`. `<type>` is one of `feat`, `fix`, `docs`, `refactor`, or `test`. `<summary>` concisely states the intent of the change.
    3. Write a body that lists the changes, one short point per logical change. Separate the body from the subject line with a blank line; otherwise, git merges them into one subject line.
    4. Commit with the message. Do not add an attribution trailer.

    Stay on the current branch and do not push.
  '';
}
