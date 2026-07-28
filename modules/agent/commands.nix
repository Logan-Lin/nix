# Shared custom commands for agent command menus.
{
  proofread = ''
    ---
    description: Proofread text for grammar and spelling issues
    argument-hint: <file>
    ---

    ## Task

    Read the file(s) specified in $ARGUMENTS and proofread it for:
    - Grammar errors
    - Spelling mistakes
    - Punctuation issues
    - Awkward phrasing

    Fix all issues directly in the file using the Edit tool. After editing, provide a brief summary of the changes made. Do not alter meaning, tone, or style. Only correct errors.
  '';

  polish = ''
    ---
    description: Aggressive proofread that fixes errors and enforces writing style rules
    argument-hint: <file>
    ---

    ## Task

    Read the file(s) specified in $ARGUMENTS, then proofread and edit it for both basic errors and writing style.

    Fix the following basic errors:
    - Grammar errors
    - Spelling mistakes
    - Punctuation issues
    - Awkward phrasing

    And enforce the following writing style rules:
    - Use plain and direct phrasing. Replace needlessly fancy, idiomatic, or indirect vocabulary, slang, syntax, or constructions with plain alternatives. For example, "use" instead of "utilize", "to" instead of "in order to", or "many" instead of "a myriad of"
    - Expand or merge a short, abstract sentence that asserts a point or opens a paragraph and leans on the next sentence to make sense. Give the sentence the specifics it needs to stand on its own, or merge it with the sentence that supplies them. When a sentence marks a transition, state how it connects to what came before and after, instead of only announcing that something changes. For example, "the rewrite cut the average response time in half" instead of "the rewrite changes everything"
    - Replace the "not A but B" phrasing, which rejects an alternative before stating the point, plus its variants such as "not A, but rather B", "it is not A, it is B", "B, not A", and "not only A but also B", with a direct statement of the point. For example, "the bottleneck is the data" instead of "the bottleneck is not the method but the data"
    - Replace hyphenated compound words, whether they join two words or more, with plain phrasing, for example "a value smaller than the limit" instead of "a smaller-than-the-limit value". Leave a hyphenated compound unchanged only when no plain phrasing can replace it, such as "state-of-the-art", "mother-in-law", and "x-ray"
    - Do not use em dashes or en dashes to connect sentences. Split into separate sentences or rephrase
    - Do not use semicolons, colons, or parentheses to join or compress sentences. Rewrite as flowing prose with separate sentences
    - When referring to the same thing, use the exact same term throughout. Remove unnecessary terms and concepts. The only exception is that shorter references can be used when the full term has been established and the short form is obvious from context

    Fix all issues directly in the file using the Edit tool. After editing, provide a brief summary of the changes made. Do not alter the underlying meaning. Only adjust wording, phrasing, and formatting to meet the rules.
  '';

  fact-check = ''
    ---
    description: Check the target file for factual errors against reputable sources
    argument-hint: <file>
    ---

    ## Task

    Read the file(s) specified in $ARGUMENTS and check it for factual errors:
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

    ## Task

    Act on the Obsidian vault TODOs identified by $ARGUMENTS.

    Use the first wikilink to identify the note that contains them.
    Interpret the rest of the arguments as an optional specification that can identify one or more TODOs, such as a checkbox line or other contextual details.
    If a specification is present, locate and act on the TODOs it identifies, treating each associated `[!todo]` callout as detailed requirements.
    If the arguments only identify a note, locate and act on every `[!todo]` callout in that note.

    Keep every TODO checkbox line and `[!todo]` callout exactly intact.
    Do not remove them or change their status after completing the work.
    The user decides whether each TODO is fully solved.
  '';

  revise = ''
    ---
    description: Revise an Obsidian vault note based on its comments
    argument-hint: <optional [[note]]>
    ---

    ## Task

    Revise the target Obsidian vault note according to the user's comments in standard blockquotes, in other words, blockquotes without a `> [!type]` callout marker on their first line.

    Use the optional wikilink $ARGUMENTS to identify the target note.
    If no wikilink was provided, infer the target note from the current session context.
    Remove the user's comments after applying all requested revisions.
  '';

  commit = ''
    ---
    description: Commit the current change as a single subject line
    ---

    ## Task

    Commit the current working tree change as one commit.

    1. Stage and review the change.
    2. Write the message as a single lowercase subject line of the form `<type>: <summary>`. `<type>` is one of `feat`, `fix`, `docs`, `refactor`, or `test`. `<summary>` is a concise description of the change
    3. Commit with the message. Write only the subject line, with no body and no attribution trailer.

    Stay on the current branch and do not push.
  '';
}
