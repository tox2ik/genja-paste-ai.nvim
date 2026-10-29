# genja-paste-ai.nvim

Paste a query into an AI search in the browser, with one current provider.
Loaded from disk by the config's `../../lua/lazyp/new/genja-paste-ai.lua`
(`dir =` spec, `cmd` and `keys` triggers; the config's `<F2>` source and the
right-click entry load it through `require('genja-paste-ai')`).

How this file is kept: one heading per feature, one bullet per decision.
Unmarked bullets were stated by jaro. `(inferred)` marks Claude's reading of the
code or history: confirm or delete. `Hint:` is a working note for Claude.

## Layout

- `lua/genja-paste-ai/init.lua`: `setup()`, `search()`, `selection()`, `set_provider()`, `current()`, `names()`, `pick()`, `command()`, `complete()`.
- `plugin/genja-paste-ai.lua`: `:PasteSearch`, alias `:Wot`; fixed-provider `:Google`, `:Perplexity`, `:Xty`.
- Moved out of the config's `lua/genja/ext/perplexity.lua` and `plugin/perplexity-search.lua`.

## Decisions

- One current provider for everything: keys, `:PasteSearch`, `<F2>`, right-click. No key per provider (UI clutter).
- Providers: AI chats perplexity, chatgpt, grok, claude, copilot, google-ai and the web searches google, bing, duckduckgo, yandex, yahoo, kagi, brave, startpage, stackoverflow take the query in the URL; gemini and manus don't: the query goes to the clipboard, the site opens, a notify says to paste.
- `:PasteSearch [-provider name] [-save] [query]`: no query = the current line, a range = the selection, `-save` alone only saves.
- `:Pplx` is gone (replaced by `:PasteSearch`); `:Wot` is the same command as `:PasteSearch`.
- `:Google` always searches google, `:Perplexity` and `:Xty` perplexity; no flags, the current provider stays.
- `-save` calls `setup({ save = fn })`; the plugin writes no file. The config's spec keeps the name in the gitignored `lua/genja/local/paste-ai.lua` (`return '<name>'`) and passes it back as `provider`.
- `<F2>` (config): one entry in group `lookup`, `paste search provider (<current>)`, opens `pick()`: `<CR>` switches for the session, `<M-s>` also saves.
- The picker marks AI providers (`ai = true`) with a leading `(ai)` and sorts entries lexically by that display text.
