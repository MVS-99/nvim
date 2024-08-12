-- Inital settings for neovim --

-- NOTE: Some general keymaps
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Moving lanes around when selected

-- Leader y pastes it into the clipboard
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

-- "Don't even press capital Q, trust me, is the worst
-- place in the universe" -> ThePrimagen
vim.keymap.set("n", "Q", "<nop>")

-- Tmux change of session
vim.keymap.set("n","<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Make the current file executable
vim.keymap.set("n", "<leader>exc","<cmd>!chmod +x %<CR>", { silent = true})

-- Resize neovim windows
vim.keymap.set('n', '<C-Up>', '1<C-w>>', { noremap = true, silent = true})
vim.keymap.set('n', '<C-Down>', '1<C-w><', { noremap = true, silent = true})

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

vim.opt.scrolloff = 5
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.g.mapleader = " "

require("lazy-setup")
