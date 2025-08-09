-- Inital settings for neovim --

-- NOTE: Some general keymaps
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Moving lanes around when selected

-- Leader y pastes it into the clipboard
vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

-- "Don't even press capital Q, trust me, is the worst
-- place in the universe" -> ThePrimagen
vim.keymap.set("n", "Q", "<nop>")

-- Tmux change of session
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Make the current file executable
vim.keymap.set("n", "<leader>exc", "<cmd>!chmod +x %<CR>", { silent = true })

-- Resize neovim windows
vim.keymap.set("n", "<C-Up>", "1<C-w>>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-Down>", "1<C-w><", { noremap = true, silent = true })

vim.opt.nu = true
vim.opt.relativenumber = true

vim.o.cursorline = true
vim.o.number = true
vim.o.termguicolors = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.laststatus = 3

vim.opt.scrolloff = 5
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.g.mapleader = " "

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
