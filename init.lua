-- Main Settings for Neovim --

-- NOTE: KEYMAPS

-- Select mapleader as <space>!
vim.g.mapleader = " "

-- * "'<" and "'>": Special marks referring to the start and the end of the
--                  last visual selection
-- * ":m": Move command; moves the addressed lines to after the target address
--         line. Because :m places after the target, moving up uses -2 while
--         down is +1.
-- * "gv": Reselects the last visual selection
-- * "=": indents the selection according to the current indent rules; thus
--        "gv=gv" means "reselect, indent, reselect again"
vim.keymap.set(
  "v",
  "J",
  ":m '>+1<CR>gv=gv",
  { desc = "Move selected lines up" }
)
vim.keymap.set(
  "v",
  "K",
  ":m '>-2<CR>gv=gv",
  { desc = "Move selected lines down" }
)

-- In Vim/Neovim, the "+" register refers to the OS "system clipboard", then
-- prexifing a yank with "+" sends the yanked text to desktop clipboard.
vim.keymap.set(
  "v",
  "<leader>y",
  '"+y',
  { desc = "Yank selection to system clipboard" }
)

-- For normal mode, "+y/+Y" keymap, you need to end prompting a motion with an
-- additional character. Each character does different things, same goes with
-- visual mode, pressing "v" and then the prompting motion. For yank you can
-- find:
--
-- * y — yank the entire current line
-- * $ — yank from cursor to end of line
-- * 0 — yank from cursor to beginning of line (exclusive of cursor char)
-- * ^ — yank from cursor to first non-blank of line
-- * gg — yank from cursor to start of file
-- * G — yank from cursor to end of file
-- * w — yank from cursor to end of current word (word = letters/digits/_)
-- * W — yank to end of current WORD (WORD = non-blank sequence)
-- * ew — yank to end of word (cursor inclusive)
-- * E — yank to end of WORD
-- * aw — yank “a word” (including surrounding space)
-- * iw — yank “inner word” (without surrounding space)
-- * aW / iW — same, but for WORD
-- * l — yank the character under cursor to the right by 1
-- * h — yank one character to the left
-- * (number)l — yank (number) characters to the right
-- * fx - yank from cursor up to and including next x
-- * tx — yank from cursor up to (but not including) next x
-- * Fx / yTx — like above, but search backward
-- * ap — yank “a paragraph” (including surrounding blank line)
-- * ip — yank “inner paragraph”
-- * as / is — “a sentence” / “inner sentence”
-- * ab / ib — “a () block” / inner ()
-- * aB / iB — “a {} block” / inner {}
-- * a[ / i[ — “a [] block” / inner []
-- * a< / i< — “a <> block” / inner <>
-- * at / it — “a tag block” / inner tag (XML/HTML)
-- * a" / i" — a double-quoted string / inner
-- * a' / i' — a single-quoted string / inner
-- * a` / i` - a backtick-quoted string / inner
-- * /word<CR> — yank from cursor to next match of “word”
-- * n] — yank to next ] (combine y with any motion you use)
-- * % — yank from cursor to matching pair ((), {}, [])
vim.keymap.set(
  "n",
  "<leader>y",
  '"+y',
  { desc = "Yank to system clipboard (await motion)" }
)
vim.keymap.set(
  "n",
  "<leader>Y",
  '"+Y',
  { desc = "Yank line/end to system clipboard" }
)

-- "Don't even press capital Q, trust me, is the worst place in the universe"
-- ThePrimagen
-- Why? Q enters Ex mode (a legacy line-editor mode). Accidental presses are
-- common as well.
-- And yes, <nop> means no operation.
vim.keymap.set("n", "Q", "<nop>")

-- Tmux change of session
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Make the current file executable
vim.keymap.set("n", "<leader>exc", "<cmd>!chmod +x %<CR>", { silent = true })

-- Resize neovim windows, adapted for Windows Terminal
vim.keymap.set(
  "n",
  "<A-h>",
  ":vertical resize -3<CR>",
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<A-j>",
  ":resize -3<CR>",
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<A-k>",
  ":resize +3<CR>",
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<A-l>",
  ":vertical resize +3<CR>",
  { noremap = true, silent = true }
)

-- NOTE: NVIM CONFIG PARAMETERS

-- Shows relative numbers for non-current lines, indicating their distance from
-- the cursor
vim.opt.relativenumber = true

-- Enables line numbners in the left gutter for each line. In combination with
-- "relativenumber" it shows the true line number of the current line
vim.opt.nu = true

-- Highlights the entire screen line under the cursor; styling is controlled by
-- the "CursorLine" highlight group and can be complemented by "CursorLineNr"
-- for the number column
vim.o.cursorline = true

-- Enables 24-bit true colour in terminals that support it, allowing modern
-- color schemes to render accurately.
vim.o.termguicolors = true

-- Inserts spaces instead of a literal tab character when pressing Tab or when
-- aut-indenting
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

-- Turns on a context-sensitive indentation mode that increases/decreases
-- indent in simple code structures (e.g. after a brace) without a full
-- language-aware engine.
vim.opt.smartindent = true

-- Disables creation of swap files (.swp), which normally protect against
-- crashes and concurret edits - diabling the warning/files. We're
-- relying on undodir/files
vim.opt.swapfile = false

-- Disables making a backup copy when writing a file. We're relying on undodir
-- & undofiles.
vim.opt.backup = false

-- Enable undofiles and setup the undodir directory. Remember:
-- * Undodir: Tells Neovim where to store per-file undo history files on disk
-- * undofile=true: Enables persistent undo so undo history survives closing
-- 		    reopening files/sessions.
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Enable highlighting of all matches of the last search pattern; matches
-- remain highlighted after the search completes until cleaned (e.g., with
 -- :nohlsearch).
vim.opt.hlsearch = true

-- Turns on incremental search: while typing a search, Neovim updates the
-- current match in real time, so the cursor jumps as the pattern is refined;
-- the search still must be confirmed with <CR> to finalize.
vim.opt.incsearch = true

-- Enables a global statusline for the entire Neovim instance instead of one
-- per window, leaving a single status bar at the bottom that reflects the
-- current window's status. Possible values:
-- * 0: Never show statuslines
-- * 1: Only if there are at least two windows
-- * 2: Only show a statusline per window
-- * 3: Show a single global status line across the whole Neovim instance
vim.opt.laststatus = 3

-- Keeps at least (number) screen lines visible above and below the cursor when
-- scrolling.
vim.opt.scrolloff = 5

-- Always shown the sign column (for Git/LSP/Diagnostics), preventing the text
-- from shifting horizontally when sign appears/disappears.
vim.opt.signcolumn = "yes"

-- Extends the isfname option so that characters @-@ (the literal '@' and '-')
-- are treated as valid filename characters
vim.opt.isfname:append("@-@")

-- Reduces the time (in milliseconds) before triggering events that rely on
-- CursorHold/CursorHoldI and swap write-outs;
vim.opt.updatetime = 50

if vim.fn.has("wsl") == 1 then
	-- Clipboard hotfix (chapuza en producción)
	vim.g.clipboard = {
		name = "WslClipboard",
		copy = {
			["+"] = "/mnt/c/Windows/System32/clip.exe",
			["*"] = "/mnt/c/Windows/System32/clip.exe",
		},
		paste = {
			["+"] = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
			["*"] = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
		},
		cache_enabled = 0,
	}
end

--NOTE: LSP keybinding and keymaps
-- for native lsp usage

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		local opts = { buffer = ev.buf, silent = true }

		-- Navigation keymaps
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)

		-- Documentation
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)

		-- Code actions
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

		-- Formatting
		if client and client.supports_method("textDocument/formatting") then
			vim.keymap.set("n", "<leader>f", function()
				vim.lsp.buf.format({ async = true })
			end, opts)
		end

		-- Enable inlay hints if supported (Neovim 0.10+)
		if client and client.supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
		end
	end,
})

-- Global diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

-- Configure LSP handlers with borders
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

-- Diagnostic configuration
vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
		source = "if_many",
	},
	float = {
		border = "rounded",
		source = "always",
	},
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

require("lazy-setup")
