-- :PasteSearch [-provider name] [-save] [query]   search with the current provider (genja-paste-ai)
--   no query: the current line; with a range (:'<,'>PasteSearch): the selection
--   -provider name: switch first; -save: keep it for later sessions (alone: only saves)
-- :Wot   the same command
-- :Google, :Perplexity, :Xty [query]   always that provider; the current one stays

---@param name string
local function define(name)
	vim.api.nvim_create_user_command(name, function(cmd)
		require('genja-paste-ai').command(cmd)
	end, {
		nargs = '*',
		range = true,
		complete = function(arglead, cmdline, cursorpos)
			return require('genja-paste-ai').complete(arglead, cmdline:sub(1, cursorpos))
		end,
		desc = 'Lookup: paste search with the current provider',
	})
end

---@param name string
---@param provider string
local function define_fixed(name, provider)
	vim.api.nvim_create_user_command(name, function(cmd)
		require('genja-paste-ai').command(cmd, provider)
	end, {
		nargs = '*',
		range = true,
		desc = 'Lookup: paste search with ' .. provider,
	})
end

define('PasteSearch')
define('Wot')
define_fixed('Google', 'google')
define_fixed('Perplexity', 'perplexity')
define_fixed('Xty', 'perplexity')
