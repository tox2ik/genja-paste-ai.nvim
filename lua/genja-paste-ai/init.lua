-- Paste a query into an AI search in the browser, with the current provider.
--   search(q)          open the current provider with `q`
--   selection()        search the visual selection
--   set_provider(name, save)   switch for the session; save: also call opts.save(name)
--   pick()             telescope picker of the providers: <CR> switch, <M-s> switch and save
--   command(cmd)       :PasteSearch [-provider name] [-save] [query]; range: the selection
-- A provider either takes the query in its URL (`url`, query appended) or not (`paste`:
-- the query goes to the clipboard and the site opens, to paste by hand).

local SRC = 'genja-paste-ai/init.lua: '

local M = {}

---@class genja-paste-ai.Provider
---@field url? string the query is appended, URI-encoded
---@field paste? string opened as is; the query goes to the clipboard

---@class genja-paste-ai.Opts
---@field provider? string current provider at start (default perplexity)
---@field save? fun(name: string) keeps the provider for later sessions (-save, <M-s>)
---@field providers? table<string, genja-paste-ai.Provider> added to or replacing the built-in ones

---@type table<string, genja-paste-ai.Provider>
M.providers = {
	perplexity = { url = 'https://www.perplexity.ai/search?q=' },
	chatgpt = { url = 'https://chatgpt.com/?q=' },
	grok = { url = 'https://grok.com/?q=' },
	gemini = { paste = 'https://gemini.google.com/app' },
	manus = { paste = 'https://manus.im/app' },
}

local state = {
	provider = 'perplexity',
	save = nil, ---@type fun(name: string)|nil
}

---@param opts? genja-paste-ai.Opts
function M.setup(opts)
	opts = opts or {}
	M.providers = vim.tbl_extend('force', M.providers, opts.providers or {})
	state.save = opts.save
	if opts.provider then
		if M.providers[opts.provider] then
			state.provider = opts.provider
		else
			vim.notify(SRC .. 'unknown provider ' .. opts.provider .. ', using ' .. state.provider, vim.log.levels.WARN)
		end
	end
end

---@return string
function M.current()
	return state.provider
end

---Provider names, sorted.
---@return string[]
function M.names()
	local names = vim.tbl_keys(M.providers)
	table.sort(names)
	return names
end

---@param name string
---@param save? boolean also keep it for later sessions (opts.save)
---@return boolean ok
function M.set_provider(name, save)
	if not M.providers[name] then
		vim.notify(SRC .. 'unknown provider ' .. name .. '; known: ' .. table.concat(M.names(), ', '), vim.log.levels.WARN)
		return false
	end
	state.provider = name
	if save then
		if state.save then
			state.save(name)
		else
			vim.notify(SRC .. 'no save function in setup(); ' .. name .. ' is for this session only', vim.log.levels.WARN)
		end
	end
	return true
end

---Search `q` with the current provider; blank queries do nothing.
---@param q string?
function M.search(q)
	q = vim.trim(q or '')
	if q == '' then
		return
	end
	local name = state.provider
	local p = M.providers[name]
	if p.url then
		vim.ui.open(p.url .. vim.uri_encode(q, 'rfc2396'))
	else
		vim.fn.setreg('+', q)
		vim.ui.open(p.paste)
		vim.notify(SRC .. name .. ': query copied, paste it with Ctrl+V')
	end
end

---Search the visual selection, then leave visual mode.
function M.selection()
	local lines = vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = vim.fn.mode() })
	vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'n', false)
	M.search(table.concat(lines, '\n'))
end

---Lines of the last visual selection (for a command with a range).
---@return string
local function last_selection()
	local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
	return table.concat(lines, '\n')
end

---:PasteSearch [-provider name] [-save] [query]
---No query: the current line, or the selection with a range. -save alone only saves.
---@param cmd vim.api.keyset.create_user_command.command_args
function M.command(cmd)
	local words = {}
	local provider = nil
	local save = false
	local i = 1
	while i <= #cmd.fargs do
		local w = cmd.fargs[i]
		if w == '-provider' then
			provider = cmd.fargs[i + 1]
			i = i + 1
		elseif w == '-save' then
			save = true
		else
			table.insert(words, w)
		end
		i = i + 1
	end
	if provider and not M.set_provider(provider, save) then
		return
	end
	if save and not provider then
		M.set_provider(state.provider, true)
	end
	local q = table.concat(words, ' ')
	if q == '' then
		if cmd.range > 0 then
			q = last_selection()
		elseif save then
			return
		else
			q = vim.api.nvim_get_current_line()
		end
	end
	M.search(q)
end

---:PasteSearch completion: provider names after -provider, else the flags.
---@param arglead string
---@param cmdline string up to the cursor
---@return string[]
function M.complete(arglead, cmdline)
	local words = vim.split(vim.trim(cmdline), '%s+')
	local prev = words[#words - (arglead ~= '' and 1 or 0)]
	local choices = { '-provider', '-save' }
	if prev == '-provider' then
		choices = M.names()
	end
	return vim.tbl_filter(function(c) return vim.startswith(c, arglead) end, choices)
end

---Telescope picker of the providers: <CR> switches for the session, <M-s> also saves.
function M.pick()
	local actions = require('telescope.actions')
	local action_state = require('telescope.actions.state')
	local function choose(bufnr, save)
		local entry = action_state.get_selected_entry()
		actions.close(bufnr)
		if entry and M.set_provider(entry.value, save) then
			local how = (save and 'saved' or 'this session')
			vim.notify(SRC .. 'provider ' .. entry.value .. ' (' .. how .. ')')
		end
	end
	require('telescope.pickers').new({}, {
		prompt_title = 'Paste search provider (<CR> session, <M-s> save)',
		finder = require('telescope.finders').new_table({
			results = M.names(),
			entry_maker = function(name)
				local display = name
				if name == state.provider then
					display = name .. ' (current)'
				end
				return { value = name, display = display, ordinal = name }
			end,
		}),
		sorter = require('telescope.config').values.generic_sorter({}),
		attach_mappings = function(bufnr, map)
			actions.select_default:replace(function() choose(bufnr, false) end)
			map({ 'i', 'n' }, '<M-s>', function() choose(bufnr, true) end, { desc = 'Paste search: provider, save' })
			return true
		end,
	}):find()
end

return M
