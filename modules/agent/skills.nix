# Shared custom skills for agents, each written to `skills/<name>/SKILL.md`.
{
  notify = ''
    ---
    name: notify
    description: Send a notification to the user through ntfy. Use only when the user explicitly asks to be notified.
    ---

    ## Task

    Send a notification to the ntfy topic `ntfy.sh/yanlincs-homelab` with `curl`:

    ```sh
    curl -s -H "Title: <title>" -d "<message>" https://ntfy.sh/yanlincs-homelab
    ```

    The notification is visible to anyone with the topic name, so do not put credentials or other sensitive data in it.
  '';

  commit = ''
    ---
    name: commit
    description: Commit a change with a subject line and a body
    ---

    ## Task

    1. Write a lowercase subject line of the form `<type>: <summary>`. `<type>` is one of `feat`, `fix`, `docs`, `refactor`, or `test`. `<summary>` concisely states the intent of the change.
    2. Write a body that lists the changes, one short point per logical change. Separate the body from the subject line with a blank line; otherwise, git merges them into one subject line.
    3. Commit with the message. Do not add an attribution trailer.
  '';
}
