# Shared custom commands for agent command menus.
{
  proofread = ''
    ---
    description: Proofread text for grammar and spelling issues
    argument-hint: <file>
    ---

    ## Target

    $ARGUMENTS

    ## Task

    Proofread the target file(s) for:
    - Grammar errors
    - Spelling mistakes
    - Punctuation issues

    After editing, provide a brief summary of the changes made. Do not alter meaning, tone, or style. Only correct errors.
  '';

  polish = ''
    ---
    description: Aggressive proofread that fixes errors and enforces writing style rules
    argument-hint: <file>
    ---

    ## Target

    $ARGUMENTS

    ## Task

    Proofread and edit the target file(s) for both basic errors and writing style.

    Fix the following basic errors:
    - Grammar errors
    - Spelling mistakes
    - Punctuation issues

    And enforce every rule in the "Writing Style" section of the global context.

    After editing, provide a brief summary of the changes made. Do not alter the underlying meaning. Only adjust wording, phrasing, and formatting to meet the rules.
  '';

  fact-check = ''
    ---
    description: Check the target file for factual errors against reputable sources
    argument-hint: <file>
    ---

    ## Target

    $ARGUMENTS

    ## Task

    Check the target file(s) for factual errors:
    - Identify concrete factual claims (names, dates, numbers, attributions, definitions, events, technical specifications, etc.)
    - Verify each claim against reputable and relatively recent sources via WebSearch and WebFetch. Prefer primary sources, official documentation, peer-reviewed publications, and well-established outlets. Avoid relying on a single low-quality source
    - Skip opinions, subjective statements, and unverifiable claims

    For any confirmed factual error, fix it directly in the file using the Edit tool with the minimal change needed to make the statement correct. Do not rewrite surrounding text, alter style, or restructure prose.

    After editing, provide a brief summary listing each correction made, with the source used to verify it. If no errors were found, state that explicitly.
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

    Use the first wikilink to identify the note that contains them.
    Interpret the rest of the target as an optional specification that can identify one or more TODOs, such as a checkbox line or other contextual details.
    If a specification is present, locate and act on the TODOs it identifies, treating each associated `[!todo]` callout as its detailed requirements.
    Otherwise, locate and act on every `[!todo]` callout in the note.

    Keep every TODO checkbox line and `[!todo]` callout exactly intact.
    Do not remove them or change their status after completing the work.
    The user decides whether each TODO is fully solved.
  '';

  revise = ''
    ---
    description: Revise an Obsidian vault note based on its comments
    argument-hint: <optional [[note]]>
    ---

    ## Target

    $ARGUMENTS

    ## Task

    Revise the target Obsidian vault note according to the user's comments in standard blockquotes, in other words, blockquotes without a `> [!type]` callout marker on their first line.

    If no target is provided, infer the target note from the current session context.
    Remove the user's comments after applying all requested revisions.
  '';

  commit = ''
    ---
    description: Commit the current change with a subject line and a body
    ---

    ## Task

    Commit the current working tree change as one commit.

    1. Stage and review the change.
    2. Write a lowercase subject line of the form `<type>: <summary>`. `<type>` is one of `feat`, `fix`, `docs`, `refactor`, or `test`. `<summary>` concisely states the intent of the change.
    3. Write a body that lists the changes, one short point per logical change.
    4. Commit with the message, with no attribution trailer.

    Stay on the current branch and do not push.
  '';
}
