return {
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "│" },
					change = { text = "│" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
				numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
				linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
				word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
				watch_gitdir = {
					follow_files = true,
				},
				auto_attach = true,
				attach_to_untracked = true,
				current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
				current_line_blame_opts = {
					virt_text = true,
					virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
					delay = 1000,
					ignore_whitespace = false,
					virt_text_priority = 100,
				},
				current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
				sign_priority = 6,
				update_debounce = 100,
				status_formatter = nil, -- Use default
				max_file_length = 40000, -- Disable if file is longer than this (in lines)
				preview_config = {
					-- Options passed to nvim_open_win
					border = "single",
					style = "minimal",
					relative = "cursor",
					row = 0,
					col = 1,
				},
				yadm = {
					enable = false,
				},
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, opts)
						opts = opts or { buffer = bufnr }
						vim.keymap.set(mode, l, r, opts)
					end

					-- Navigation
					map("n", "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(gs.next_hunk)
						return "<Ignore>"
					end, { expr = true })

					map("n", "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true })

					-- Actions
					map("n", "<leader>ghs", gs.stage_hunk)
					map("n", "<leader>ghr", gs.reset_hunk)
					map("v", "<leader>ghs", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end)
					map("v", "<leader>ghr", function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end)
					map("n", "<leader>gbs", gs.stage_buffer)
					map("n", "<leader>ghu", gs.undo_stage_hunk)
					map("n", "<leader>gbr", gs.reset_buffer)
					map("n", "<leader>ghp", gs.preview_hunk)
					map("n", "<leader>ghB", function()
						gs.blame_line({ full = true })
					end)
					map("n", "<leader>gtb", gs.toggle_current_line_blame)
					map("n", "<leader>ghd", gs.diffthis)
					map("n", "<leader>ghD", function()
						gs.diffthis("~")
					end)
					map("n", "<leader>gtd", gs.toggle_deleted)

					-- Text object
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
				end,
			})
		end,
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"sindrets/diffview.nvim",
				dependencies = {
					"nvim-tree/nvim-web-devicons",
				},
				opts = {
					use_icons = true,
					key_bindings = {
						view = {
							["<tab>"] = "select_next_entry",
							["<s-tab>"] = "select_prev_entry",
							["-"] = "toggle_stage_entry",
							["X"] = "restore_entry",
							["R"] = "refresh_files",
							["<leader>e"] = "toggle_files",
						},
						file_panel = {
							["j"] = "next_entry",
							["k"] = "prev_entry",
							["o"] = "open",
							["df"] = "focus_files",
						},
						file_history_panel = {
							["y"] = "copy_hash",
							["g!"] = "options",
							["<tab>"] = "select_entry",
							["q"] = "close_window",
						},
						option_panel = {
							["<tab>"] = "select_entry",
							["q"] = "close_window",
						},
					},
					vim.keymap.set("n", "<leader>dvo", ":DiffviewOpen<CR>"),
				},
			},
			opts = {
				disable_hint = false,
				kind = "tab", -- open in new tab, other options: split, floating
				integrate_with_diffview = true,
			},
		},
	},
}
