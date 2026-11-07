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
}
