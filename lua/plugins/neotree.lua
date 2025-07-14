return {
	{
		"antosha417/nvim-lsp-file-operations",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-neo-tree/neo-tree.nvim",
		},
		config = function()
			require("lsp-file-operations").setup()
		end,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
			{ "3rd/image.nvim", opts = {} }, -- Image support in preview window
			{
				"s1n7ax/nvim-window-picker", --for open_with_window_picker keymaps
				version = "2.*",
				config = function()
					require("window-picker").setup({
						filter_rules = {
							include_current_win = false,
							autoselect_one = true,
							-- filter using buffer options
							bo = {
								-- if the file type is one of the following, the window will be ignored
								filetype = { "neo-tree", "neo-tree-popup", "notify" },
								-- if the buffer type is one of the following, the window will be ignored
								buftype = { "terminal", "quickfix" },
							},
						},
					})
				end,
			},
		},
		lazy = false,
		keys = {
			{ "<leader>ntg", "<Cmd>Neotree toggle<CR>", desc = "Toggle Neo-tree" },
		},
		---@module "neo-tree"
		---@type neotree.Config?
		opts = {
			close_if_last_window = false, -- Close Neo-Tree if it is the last window left in the tab
			popup_border_style = "", -- "" to use 'winborder' on Neovim v0.11+, prev "NC"
			enable_git_status = true,
			enable_diagnostics = true,
			-- when opening files, do not use windows containing these filetypes or buftypes:
			open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
			open_files_using_relative_paths = false,
			sort_case_insensitive = false,
			-- For sort function nil would be the default
			-- I will provide a better one if this does not crash everything
			-- nor the world ends before I finish it. Who knows tho, lets see
			sort_function = function(a, b)
				-- Helper function for natural alphanumeric sorting
				local function natural_cmp(str1, str2)
					-- Convert strings to lowercase for case-insensitive comparison
					str1, str2 = str1:lower(), str2:lower()

					-- Split strings into chunks of text and numbers
					local function split_alphanum(str)
						local chunks = {}
						for chunk in str:gmatch("[^%d]*%d*") do
							if chunk ~= "" then
								table.insert(chunks, chunk)
							end
						end
						return chunks
					end

					local chunks1 = split_alphanum(str1)
					local chunks2 = split_alphanum(str2)

					-- Compare chunks pairwise
					for i = 1, math.max(#chunks1, #chunks2) do
						local chunk1 = chunks1[i] or ""
						local chunk2 = chunks2[i] or ""

						-- Extract numeric and text parts
						local num1 = chunk1:match("(%d+)")
						local num2 = chunk2:match("(%d+)")
						local text1 = chunk1:match("([^%d]*)")
						local text2 = chunk2:match("([^%d]*)")

						-- Compare text parts first
						if text1 ~= text2 then
							return text1 < text2
						end

						-- If text parts are equal, compare numeric parts
						if num1 and num2 then
							local n1, n2 = tonumber(num1), tonumber(num2)
							if n1 ~= n2 then
								return n1 < n2
							end
						elseif num1 then
							return false -- Numbers come after non-numbers
						elseif num2 then
							return true -- Non-Numbers come before numbers
						end
					end
					return #chunks1 < #chunks2
				end

				-- Get clean names without path
				local name_a = vim.fn.fnamemodify(a.path, ":t")
				local name_b = vim.fn.fnamemodify(b.path, ":t")

				-- Priority 1: Directories always come first
				if a.type ~= b.type then
					if a.type == "directory" then
						return true
					end
					if b.type == "directory" then
						return false
					end
				end

				-- Priority 2: Hidden files (starting with .) come after visible files
				local a_hidden = name_a:sub(1, 1) == "."
				local b_hidden = name_b:sub(1, 1) == "."
				if a_hidden ~= b_hidden then
					return not a_hidden --visible files first
				end

				-- Priority 3: Important files first (README, LICENSE, etc.)
				local important_files = {
					["readme.md"] = 1,
					["readme.txt"] = 1,
					["readme"] = 1,
					["license"] = 2,
					["license.md"] = 2,
					["license.txt"] = 2,
					["changelog.md"] = 3,
					["changelog"] = 3,
					["makefile"] = 4,
					["dockerfile"] = 4,
					["package.json"] = 5,
					["cargo.toml"] = 5,
					["pom.xml"] = 5,
				}

				local weight_a = important_files[name_a:lower()] or 999
				local weight_b = important_files[name_b:lower()] or 999

				if weight_a ~= weight_b then
					return weight_a < weight_b
				end

				-- Priority 4: Natural alphanumeric sorting
				return natural_cmp(name_a, name_b)
			end,
			default_component_configs = {
				container = {
					enable_character_fade = true,
				},
				indent = {
					padding = 1, --  a bit of padding on left hand side
					indent_size = 2,
					-- indent guides
					with_markers = true,
					indent_marker = "│",
					last_indent_marker = "└",
					highlight = "NeoTreeIndentMarker",
					-- expander config, for nesting files
					with_expanders = nil, --nil && file nesting enabled -> expanders enabled
					expander_collapsed = "",
					expander_expansed = "",
					expander_highlight = "NeoTreeExpander",
				},
				icon = {
					folder_closed = "",
					folder_open = "",
					folder_empty = "󰜌",
					provider = function(icon, node, state) -- default icon provider is nvim-web-devicons
						if node.type == "file" or node.type == "terminal" then
							local success, web_devicons = pcall(require, "nvim-web-devicons")
							local name = node.type == "terminal" and "terminal" or node.name
							if success then
								local devicon, hl = web_devicons.get_icon(name)
								icon.text = devicon or icon.text
								icon.highlight = hl or icon.highlight
							end
						end
					end,
					-- Fallback if nvim-web-devicons fails
					default = "*",
					highlight = "NeoTreeFileIcon",
				},
				modified = {
					symbol = "[+]",
					highlight = "NeoTreeModified",
				},
				name = {
					trailing_slash = false,
					use_git_status_colors = true,
					highlight = "NeoTreeFileName",
				},
				git_status = {
					symbols = {
						-- Change type
						added = "", -- Rather than ✚ as this is redundant info using git_status_colors
						modified = "", -- Same behvaiour, in substitution of 
						deleted = "✖", -- Only used in the git_status source
						renamed = "󰁕", -- Only used in the git_status source
						-- Status type
						untracked = "",
						ignored = "",
						unstaged = "󰄱",
						staged = "",
						conflict = "",
					},
				},
				file_size = {
					enabled = true,
					width = 12, -- width of the column
					required_width = 64, -- min width of window required to show this column
				},
				type = {
					enabled = true,
					width = 10,
					required_width = 122,
				},
				last_modified = {
					enabled = true,
					width = 20,
					required_width = 88,
				},
				created = {
					enabled = true,
					width = 20,
					required_width = 110,
				},
				symlink_target = {
					enabled = false,
				},
			},
			-- A list of functions, each representing a global custom command
			-- that will be available in all sources (if not overridden in `opts[source_name].commands`)
			-- see `:h neo-tree-custom-commands-global`
			commands = {},
			window = {
				position = "left",
				width = 40,
				mapping_options = {
					noremap = true,
					nowait = true,
				},
				mappings = {
					["<space>"] = {
						"toggle_node",
						nowait = false, -- disabled so existing combos can work
					},
					["<2-LeftMouse"] = "open",
					["<cr>"] = "open_drop",
					["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = true } },
					["l"] = "focus_preview",
					["S"] = "split_with_window_picker",
					["s"] = "vsplit_with_window_picker",
					["t"] = "open_tab_drop",
				},
			},
		},
	},
}
