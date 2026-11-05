# genja-paste-ai.nvim

Send a query from Neovim to a web or AI search in the browser, with one
current provider for everything.

- AI chats: perplexity (default), chatgpt, grok, claude, copilot, google-ai,
  gemini, manus.
- Web searches: google, bing, duckduckgo, yandex, yahoo, kagi, brave,
  startpage, stackoverflow.
- Most take the query in the URL. gemini and manus don't: the query goes to the
  clipboard, the site opens, and a notification says to paste.

## Requirements

- Neovim 0.11+ (opens the browser with `vim.ui.open`)

## Install (lazy.nvim)

```lua
{
    'tox2ik/genja-paste-ai.nvim',
    cmd = { 'PasteSearch', 'Wot', 'Google', 'Perplexity', 'Xty' },
    keys = {
        { '<leader>ps', function() require('genja-paste-ai').selection() end, mode = 'x', desc = 'Lookup: paste search selection' },
    },
    opts = {
        provider = 'perplexity', -- current provider at start
        -- save = function(name) ... end, -- keep the provider for later sessions (-save, <M-s>)
        -- providers = { mysearch = { url = 'https://example.com/?q=', ai = false } },
    },
}
```

`-save` and `<M-s>` call your `save(name)`; the plugin writes no file. Pass the
saved name back as `provider` next time.

## Commands

| Command | Action |
|---|---|
| `:PasteSearch [query]` | search with the current provider; no query: the current line; a range: the selection |
| `:PasteSearch -provider <name> [query]` | switch the provider, then search |
| `:PasteSearch -provider <name> -save` | switch and save, no search |
| `:Wot` | same as `:PasteSearch` |
| `:Google`, `:Perplexity`, `:Xty` | always that provider (`:Xty` is perplexity); the current one stays |

## Lua API

`search(q, name)`, `selection()`, `selection_pick()`, `pick(q)` (a picker: `<CR>`
switches for the session, `<M-s>` also saves), `set_provider(name, save)`,
`current()`, `names()`.

## License

MIT
