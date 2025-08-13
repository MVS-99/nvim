return {
	-- Mason package manager
	{
		"mason-org/mason.nvim",
		version = "^2.0.0",
		build = ":MasonUpdate",
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	}, -- Mason-LSPConfig bridge (reduced functionality in 0.11+)
	{
		"mason-org/mason-lspconfig.nvim",
		version = "^2.0.0",
		dependencies = { "mason-org/mason.nvim" },
		config = function()
			-- Definitions for gopls
			--- @class go_dir_custom_args
			--- @field envvar_id string
			--- @field custom_subdir string?

			-- Initialization for gopls
			local mod_cache = nil
			local std_lib = nil

			--INFO: This functions are auxiliar to LSP that I am using

			-- Used to detect when a Rust file being edited is part of an external library or dependency,
			-- rather than the current project's source code
			local function is_rust_library(fname)
				local user_home = vim.fs.normalize(vim.env.HOME)
				local cargo_home = os.getenv("CARGO_HOME") or user_home .. "/.cargo"
				local registry = cargo_home .. "/registry/src"
				local git_registry = cargo_home .. "/git/checkouts"

				local rustup_home = os.getenv("RUSTUP_HOME") or user_home .. "/.rustup"
				local toolchains = rustup_home .. "/toolchains"

				for _, item in ipairs({ toolchains, registry, git_registry }) do
					if vim.fs.relpath(item, fname) then
						local clients = vim.lsp.get_clients({ name = "rust_analyzer" })
						return #clients > 0 and clients[#clients].config.root_dir or nil
					end
				end
				return nil
			end

			local function reload_rust_workspace(bufnr)
				local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "rust_analyzer" })
				for _, client in ipairs(clients) do
					vim.notify("Reloading Cargo Workspace")
          ---@diagnostic disable-next-line:param-type-mismatch
					client:request("rust-analyzer/reloadWorkspace", nil, function(err)
						if err then
							error(tostring(err))
						end
						vim.notify("Cargo Workspace reloaded")
					end, 0)
				end
			end

			local function switch_c_cpp_source_header(bufnr, client)
				local method_name = "textDocument/switchSourceHeader"
        ---@diagnostic disable-next-line:param-type-mismatch
				if not client or not client:supports_method(method_name) then
					return vim.notify(
						("method %s is not supported by any servers active on the current buffer"):format(method_name)
					)
				end
				local params = vim.lsp.util.make_text_document_params(bufnr)
        ---@diagnostic disable-next-line:param-type-mismatch
				client:request(method_name, params, function(err, result)
					if err then
						error(tostring(err))
					end
					if not result then
						return vim.notify("Corresponding file cannot be determined")
					end
					vim.cmd.edit(vim.uri_from_fname(result))
				end, bufnr)
			end

			local function symbol_c_cpp_info(bufnr, client)
        local method_name = 'textDocument/symbolInfo'
        ---@diagnostic disable-next-line:param-type-mismatch
				if not client or not client:supports_method(method_name) then
					return vim.notify("Clangd client not found", vim.log.levels.ERROR)
				end
				local win = vim.api.nvim_get_current_win()
				local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
        ---@diagnostic disable-next-line:param-type-mismatch
				client:request(method_name, params, function(err, res)
					if err or #res == 0 then
						-- Clangd always returns an error, there is no reason to parse it
						return
					end
					local container = string.format("container: %s", res[1].containerName) ---@type string
					local name = string.format("name: %s", res[1].name) ---@type string
					vim.lsp.util.open_floating_preview({ name, container }, "", {
						height = 2,
						width = math.max(string.len(name), string.len(container)),
						focusable = false,
						focus = false,
						title = "Symbol Info",
					})
				end, bufnr)
			end

			---@param custom_args go_dir_custom_args
			---@param on_complete fun(dir: string | nil)
			local function identify_go_dir(custom_args, on_complete)
				local cmd = { "go", "env", custom_args.envvar_id }
				vim.system(cmd, { text = true }, function(output)
					local res = vim.trim(output.stdout or "")
					if output.code == 0 and res ~= "" then
						if custom_args.custom_subdir and custom_args.custom_subdir ~= "" then
							res = res .. custom_args.custom_subdir
						end
						on_complete(res)
					else
						vim.schedule(function()
							vim.notify(
								("[gopls] identify " .. custom_args.envvar_id .. " dir cmd failed with code %d: %s\n%s"):format(
									output.code,
									vim.inspect(cmd),
									output.stderr
								)
							)
						end)
						on_complete(nil)
					end
				end)
			end

			---@return string?
			local function get_go_std_lib_dir()
				if std_lib and std_lib ~= "" then
					return std_lib
				end
				identify_go_dir({ envvar_id = "GOROOT", custom_subdir = "/src" }, function(dir)
					if dir then
						std_lib = dir
					end
				end)
				return std_lib
			end

			---@return string?
			local function get_go_mod_cache_dir()
				if mod_cache and mod_cache ~= "" then
					return mod_cache
				end
				identify_go_dir({ envvar_id = "GOMODCACHE" }, function(dir)
					if dir then
						mod_cache = dir
					end
				end)
				return mod_cache
			end

			---@param fname string
			---@return string?
			local function get_go_root(fname)
				if mod_cache and fname:sub(1, #mod_cache) == mod_cache then
					local clients = vim.lsp.get_clients({ name = "gopls" })
					if #clients > 0 then
						return clients[#clients].config.root_dir
					end
				end
				if std_lib and fname:sub(1, #std_lib) == std_lib then
					local clients = vim.lsp.get_clients({ name = "gopls" })
					if #clients > 0 then
						return clients[#clients].config.root_dir
					end
				end
				return vim.fs.root(fname, "go.work") or vim.fs.root(fname, "go.mod") or vim.fs.root(fname, ".git")
			end

			local function set_python_path(path)
				local clients = vim.lsp.get_clients({
					bufnr = vim.api.nvim_get_current_buf(),
					name = "basedpyright",
				})
				for _, client in ipairs(clients) do
					if client.settings then
						client.settings.python =
							vim.tbl_deep_extend("force", client.settings.python, { pythonPath = path })
					else
						client.config.settings =
							vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = path } })
					end
					client.notify("workspace/didChangeConfiguration", { settings = nil })
				end
			end

      local function buf_latex_build(client, bufnr)
        local win = vim.api.nvim_get_current_win()
        local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
        client:request('textDocument/build', params, function(err, result)
          if err then
            error(tostring(err))
          end
          local texlab_build_status = {
            [0] = 'Success',
            [1] = 'Error',
            [2] = 'Failure',
            [3] = 'Cancelled',
          }
          vim.notify('Build ' .. texlab_build_status[result.status], vim.log.levels.INFO)
        end, bufnr)
      end

      local function buf_latex_search(client, bufnr)
        local win = vim.api.nvim_get_current_win()
        local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
        client:request('textDocument/forwardSearch', params, function(err, result)
          if err then
            error(tostring(err))
          end
          local texlab_forward_status = {
            [0] = 'Success',
            [1] = 'Error',
            [2] = 'Failure',
            [3] = 'Unconfigured',
          }
          vim.notify('Search ' .. texlab_forward_status[result.status], vim.log.levels.INFO)
        end, bufnr)
      end

      local function buf_latex_cancel_build(client,bufnr)
        return client:exec_cmd({
          title = 'cancel',
          command = 'texlab.cancelBuild',
        }, { bufnr = bufnr })
      end


      local function dependency_latex_graph(client)
        client:exec_cmd({ command = 'texlab.showDependencyGraph' }, { bufnr = 0 }, function(err, result)
          if err then
            return vim.notify(err.code .. ': ' .. err.message, vim.log.levels.ERROR)
          end
          vim.notify('The dependency graph has been generated:\n' .. result, vim.log.levels.INFO)
        end)
      end

      local function command_latex_factory(cmd)
        local cmd_tbl = {
          Auxiliary = 'texlab.cleanAuxiliary',
          Artifacts = 'texlab.cleanArtifacts',
        }
        return function(client, bufnr)
          return client:exec_cmd({
            title = ('clean_%s'):format(cmd),
            command = cmd_tbl[cmd],
            arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
          }, { bufnr = bufnr }, function(err, _)
            if err then
              vim.notify(('Failed to clean %s files: %s'):format(cmd, err.message), vim.log.levels.ERROR)
            else
              vim.notify(('Command %s executed successfully'):format(cmd), vim.log.levels.INFO)
            end
          end)
        end
      end

      local function buf_latex_find_envs(client, bufnr)
        local win = vim.api.nvim_get_current_win()
        client:exec_cmd({
          command = 'texlab.findEnvironments',
          arguments = { vim.lsp.util.make_position_params(win, client.offset_encoding) },
        }, { bufnr = bufnr }, function(err, result)
          if err then
            return vim.notify(err.code .. ': ' .. err.message, vim.log.levels.ERROR)
          end
          local env_names = {}
          local max_length = 1
          for _, env in ipairs(result) do
            table.insert(env_names, env.name.text)
            max_length = math.max(max_length, string.len(env.name.text))
          end
          for i, name in ipairs(env_names) do
            env_names[i] = string.rep(' ', i - 1) .. name
          end
          vim.lsp.util.open_floating_preview(env_names, '', {
            height = #env_names,
            width = math.max((max_length + #env_names - 1), (string.len 'Environments')),
            focusable = false,
            focus = false,
            title = 'Environments',
          })
        end)
      end

      local function buf_latex_change_env(client, bufnr)
        local new
        vim.ui.input({ prompt = 'New environment name: ' }, function(input)
          new = input
        end)
        if not new or new == '' then
          return vim.notify('No environment name provided', vim.log.levels.WARN)
        end
        local pos = vim.api.nvim_win_get_cursor(0)
        return client:exec_cmd({
          title = 'change_environment',
          command = 'texlab.changeEnvironment',
          arguments = {
            {
              textDocument = { uri = vim.uri_from_bufnr(bufnr) },
              position = { line = pos[1] - 1, character = pos[2] },
              newName = tostring(new),
            },
          },
        }, { bufnr = bufnr })
      end

			require("mason-lspconfig").setup({
				ensure_installed = {
					-- Coding plugins and plugin configuration
					"lua_ls",
					-- Assembly
					"asm_lsp",
					-- C/C++
					"clangd",
					-- Rust
					"rust_analyzer",
					-- Go
					"gopls",
					-- Python
					"basedpyright",
					-- Ruby
					"ruby_lsp",
					-- Typescript, javascript
					"ts_ls",
					-- Additional
					"bashls",
					"jsonls",
					"yamlls",
					"neocmake",
					-- PHP
					"phpactor",
					-- html
					"html",
					--css,
					"cssls",
					-- Nim
					"nim_langserver",
          -- LaTeX
          "texlab"
				},
				automatic_enable = true, -- Uses vim.lsp.enable() automatically
			})

			-- Native LSP configuration (LUA)
			vim.lsp.config.lua_ls = {
				cmd = { "lua-language-server" },
				filetypes = { "lua" },
				root_markers = {
					".luarc.json",
					".luarc.jsonc",
					".luacheckrc",
					".stylua,toml",
					"stylua.toml",
					"selene.toml",
					"selene.yml",
					".nvim.lua",
					"init.lua",
					".git",
				},
				settings = {
					Lua = {
						-- Runtime configuration for Neovim
						runtime = {
							version = "LuaJIT",
							path = { "lua/?.lua", "lua/?/init.lua" },
						},
						-- Diagnostics optimized for Neovim development
						diagnostics = {
							globals = {
								"vim", -- Core vim global
								"describe", -- For testing frameworks
								"it", -- For testing frameworks
								"before_each", -- For testing frameworks
								"after_each", -- For testing frameworks
							},
							disable = {
								"missing-fields", -- Reduces noise in plugin dev
							},
						},
						-- Workplace configuration for Neovim
						workspace = {
							checkThirdParty = false,
							library = {
								vim.env.VIMRUNTIME, -- Neovim runtime
								vim.fn.stdpath("config"), -- Config directory
								vim.fn.stdpath("data") .. "/lazy", -- Lazy plugin directory
								-- Specific plugin paths if needed
								-- '${3rd}/luv/library'                              -- Will be handled by lazydev
							},
							maxPreload = 100000,
							preloadFileSize = 10000,
						},
						-- Completion settings
						completion = {
							callSnippet = "Replace",
							keywordSnippet = "Replace",
							displaycontext = 6,
						},
						-- Enhanced hint support
						hint = {
							enable = true,
							arrayIndex = "Disable", -- Reduces visual noise
							setType = true,
						},
						-- Formatting
						format = { enable = false },
						-- Telemetry
						telemetry = { enable = false },
						-- Semantic tokens (highlighting)
						semantic = {
							enable = true,
							variable = true,
							annotation = true,
							keyword = true,
						},
					},
				},
			}

			---@brief
			---
			--- https://clangd.llvm.org/installation.html
			---
			--- - NOTE:** Clang >= 11 is recommended! See [#23](https://github.com/neovim/nvim-lspconfig/issues/23).
			--- - If `compile_commands.json` lives in a build directory, you should
			---   symlink it to the root of your source tree.
			---   ```
			---   ln -s /path/to/myproject/build/compile_commands.json /path/to/myproject/
			---   ```
			--- - clangd relies on a [JSON compilation database](https://clang.llvm.org/docs/JSONCompilationDatabase.html)
			---   specified as compile_commands.json, see https://clangd.llvm.org/installation#compile_commandsjson

			-- C / C++ language server
			vim.lsp.config.clangd = {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=iwyu",
					"--completion-style=detailed",
					"--function-arg-placeholders",
					"--fallback-style=llvm",
					"--pch-storage=memory",
					"--suggest-missing-includes",
					"--cross-file-rename",
				},
				filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
				root_markers = {
					".clangd",
					".clang-tidy",
					".clang-format",
					"compile_commands.json",
					"compile_flags.txt",
					"configure.ac", -- Autotools
					".git",
				},
				single_file_support = true,
				capabilities = {
					textDocument = {
						completion = {
							editsNearCursor = true,
						},
					},
					offsetEncoding = { "utf-8", "utf-16" },
				},
				on_init = function(client, init_result)
					---@class ClangdInitializeResult: lsp.InitializeResult
					---@field offsetEncoding? string

					if init_result.offsetEncoding then
						client.offset_encoding = init_result.offsetEncoding
					end
				end,
        ---@param client vim.lsp.Client
        ---@param bufnr integer
				on_attach = function(client, bufnr)
					vim.api.nvim_buf_create_user_command(bufnr, "LspClangdSwitchSourceHeader", function()
						switch_c_cpp_source_header(bufnr,client)
					end, { desc = "Switch between C/C++ source/header" })

					vim.api.nvim_buf_create_user_command(bufnr, "LspClangdShowSymbolInfo", function()
						symbol_c_cpp_info(bufnr, client)
					end, { desc = "Show symbol info" })
				end,
				init_options = {
					usePlaceholders = true,
					completeUnimported = true,
					clangdFileStatus = true,
					fallbackFlags = { "--std=c++23", "--std=c23" },
				},
			}

			---@brief
			---
			--- https://github.com/rust-lang/rust-analyzer
			---
			--- rust-analyzer (aka rls 2.0), a language server for Rust
			vim.lsp.config.rust_analyzer = {
				cmd = { "rust-analyzer" },
				filetypes = { "rust" },
				single_file_support = true,
				root_dir = function(bufnr, on_dir)
					local fname = vim.api.nvim_buf_get_name(bufnr)
					local reused_dir = is_rust_library(fname)
					if reused_dir then
						on_dir(reused_dir)
						return
					end

					local cargo_crate_dir = vim.fs.root(fname, { "Cargo.toml" })
					local cargo_workspace_root

					if cargo_crate_dir == nil then
						on_dir(
							vim.fs.root(fname, { "rust-project.json" })
								or vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
						)
						return
					end

					local cmd = {
						"cargo",
						"metadata",
						"--no-deps",
						"--format-version",
						"1",
						"--manifest-path",
						cargo_crate_dir .. "/Cargo.toml",
					}

					vim.system(cmd, { text = true }, function(output)
						if output.code == 0 then
							if output.stdout then
								local result = vim.json.decode(output.stdout)
								if result["workspace_root"] then
									cargo_workspace_root = vim.fs.normalize(result["workspace_root"])
								end
							end
							on_dir(cargo_workspace_root or cargo_crate_dir)
						else
							vim.schedule(function()
								vim.notify(
									("[rust-analyzer] cmd failed with code %d: %s\n%s"):format(
										output.code,
										cmd,
										output.stderr
									)
								)
							end)
						end
					end)
				end,
				capabilities = {
					experimental = {
						serverStatusNotification = true,
					},
				},
				before_init = function(init_params, config)
					-- As indicated by https://github.com/rust-lang/rust-analyzer/blob/eb5da56d839ae0a9e9f50774fa3eb78eb0964550/docs/dev/lsp-extensions.md?plain=1#L26
					if config.settings and config.settings["rust-analyzer"] then
						init_params.initializationOptions = config.settings["rust-analyzer"]
					end
				end,
				on_attach = function(_, bufnr)
					vim.api.nvim_buf_create_user_command(bufnr, "LspCargoReload", function()
						reload_rust_workspace(bufnr)
					end, { desc = "Reload current cargo workspace" })
				end,
			}

			---@brief
			---
			--- https://github.com/golang/tools/tree/master/gopls
			---
			--- Google's lsp server for golang.
			vim.lsp.config.gopls = {
				cmd = { "gopls" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				root_dir = function(bufnr, on_dir)
					local fname = vim.api.nvim_buf_get_name(bufnr)
					get_go_mod_cache_dir()
					get_go_std_lib_dir()
					-- see: https://github.com/neovim/nvim-lspconfig/issues/804
					on_dir(get_go_root(fname))
				end,
				settings = {
					gopls = {
						completeUnimported = true,
						usePlaceholders = true,
						analyses = {
							unusedparams = true,
						},
						staticcheck = true,
						gofumpt = true,
					},
				},
			}

			---@brief
			---
			--- https://github.com/microsoft/pyright
			---
			--- `pyright`, a static type checker and language server for python
			vim.lsp.config.basedpyright = {
				cmd = { "basedpyright-langserver", "--stdio" },
				filetypes = { "python" },
				root_markers = {
					"pyproject.toml",
					"setup.py",
					"setup.cfg",
					"requirements.txt",
					"Pipfile",
					"pyrightconfig.json",
					".git",
				},
				settings = {
					basedpyright = {
						analysis = {
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
							diagnosticMode = "openFilesOnly",
						},
					},
				},
				on_attach = function(client, bufnr)
					vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightOrganizeImports", function()
						client:exec_cmd({
							command = "basedpyright.organizeimports",
							arguments = { vim.uri_from_bufnr(bufnr) },
						})
					end, {
						desc = "Organize Imports",
					})
					vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightSetPythonPath", set_python_path, {
						desc = "Reconfigure basedpyright with the provided python path",
						nargs = 1,
						complete = "file",
					})
				end,
			}

			---@brief
			---
			--- https://shopify.github.io/ruby-lsp/
			---
			--- This gem is an implementation of the language server protocol specification for
			--- Ruby, used to improve editor features.
			vim.lsp.config.ruby_lsp = {
				cmd = { "ruby-lsp" },
				filetypes = { "ruby", "eruby" },
				root_markers = { "Gemfile", ".git" },
				init_options = {
					addonSettings = {
						-- Enhanced addon settings from comprehensive functionality
						RubyLSPRails = {
							-- Ruby LSP rails addon configuration
							enablePendingMigrationsPrompt = false,
						},
						-- RSpec addon settings
						RubyLSPRspec = {
							rspeccommand = nil, -- Auto-detect based on binstub/Gemfile
						},
						-- Debug addon settings
						RubyLSPDebug = {
							enable = true,
						},
					},
				},
				single_file_support = true,
				formatter = "rubocop",
				settings = {
					ruby = {
						updateBundleOnSave = true,
						experimentalFeatures = true,
					},
				},
			}

			---@brief
			---
			--- https://github.com/bergercookie/asm-lsp
			---
			--- Language Server for NASM/GAS/GO Assembly
			vim.lsp.config.asm_lsp = {
				cmd = { "asm-lsp" },
				filetypes = { "asm", "vmasm", "s", "S" },
				root_markers = { ".asm-lsp.toml", ".git" },
			}

			---@brief Language server for bash, written using tree sitter in typescript.
			--- https://github.com/bash-lsp/bash-language-server
			vim.lsp.config.bashls = {
				cmd = { "bash-language-server", "start" },
				settings = {
					bashIde = {
						-- Glob pattern for finding and parsing shell script files in the workspace.
						-- Used by the background analysis features across files.

						-- Prevent recursive scanning which will cause issues when opening a file
						-- directly in the home directory (e.g. ~/foo.sh).

						-- Default upstream pattern is "**/*@(.sh|.inc|.bash|.command)".
						globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
					},
				},
				filetypes = { "bash", "sh" },
				root_markers = { ".git" },
			}

			---@brief vscode-json-language-server, a language server for JSON and JSON schema
			--- https://github.com/microsoft/vscode-json-languageservice
			vim.lsp.config.jsonls = {
				cmd = { "vscode-json-language-server", "--stdio" },
				filetypes = { "json", "jsonc" },
				init_options = {
					provideFormatter = true,
				},
				root_markers = { ".git" },
			}

			---@brief yaml-language-server, a language server for YAML and YAML schema
			--- https://github.com/redhat-developer/yaml-language-server
			---
			---  To use a schema for validation, there are two options:
			---  1. Add a modeline to the file. A modeline is a comment of the form:
			---  ```
			---  yaml-language-server: $schema=<urlToTheSchema|relativeFilePath|absoluteFilePath}>
			---  ```
			---  where the relative filepath is the path relative to the open yaml file, and the absolute filepath
			---  is the filepath relative to the filesystem root ('/' on unix systems)
			---
			---  2. Associated a schema url, relative, or absolute (to root of project, not to filesystem root) path to
			---  the a glob pattern relative to the detected project root. Check `:checkhealth vim.lsp` to determine the resolved project
			---  root:
			---  ```lua
			---  vim.lsp.config('yamlls', {
			---     ...
			---     settings = {
			---     yaml = {
			---     ... -- other settings. Note this overrides the lspconfig defaults
			---     schemas = {
			---     ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
			---     ["../path/relative/to/file.yml"] = "/.github/workflows/*",
			---     ["/path/from/root/of/project"] = "/.github/workflows/*",
			--- },
			--- },
			--- }
			---  })
			---  ```
			vim.lsp.config.yamlls = {
				cmd = { "yaml-language-server", "--stdio" },
				filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
				root_markers = { ".git" },
				settings = {
					-- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
					redhat = { telemetry = { enabled = false } },
				},
			}

			---@brief CMake LSP Implementation
			--- https://github.com/Decodetalkers/neocmakelsp
			vim.lsp.config.neocmake = {
				cmd = { "neocmakelsp", "--stdio" },
				filetypes = { "cmake" },
				root_markers = { ".git", "build", "cmake" },
			}

			---@brief Typescript
			--- https://github.com/typescript-language-server/typescript-language-server
			vim.lsp.config.ts_ls = {
				init_options = { hostInfo = "neovim" },
				cmd = { "typescript-language-server", "--stdio" },
				filetypes = {
					"javascript",
					"javascriptreact",
					"javascript.jsx",
					"typescript",
					"typescriptreact",
					"typescript.tsx",
				},
				root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
				handlers = {
					-- handle rename request for certain code actions like extracting functions / types
					["_typescript.rename"] = function(_, result, ctx)
						local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
						vim.lsp.util.show_document({
							uri = result.textDocument.uri,
							range = {
								start = result.position,
								["end"] = result.position,
							},
						}, client.offset_encoding)
						vim.lsp.buf.rename()
						return vim.NIL
					end,
				},
        commands = {
          ['editor.action.showReferences'] = function(command, ctx)
            local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
            local file_uri, position, references = unpack(command.arguments)
            local quickfix_items = vim.lsp.util.locations_to_items(references, client.offset_encoding)

            vim.fn.setqflist({}, ' ', {
              title = command.title,
              items = quickfix_items,
              context = {
                command = command,
                bufnr = ctx.bufnr,
              },
            })

            vim.lsp.util.show_document({
              url = file_uri,
              range = {
                start = position,
                ['end'] = position,
              },
            }, client.offset_encoding)

            vim.cmd('botright copen')
          end,
        },
				on_attach = function(client, bufnr)
					-- ts_ls provides `source.*` code actions that apply to the whole file. These only appear in
					-- `vim.lsp.buf.code_action()` if specified in `context.only`.
					vim.api.nvim_buf_create_user_command(bufnr, "LspTypescriptSourceAction", function()
						local source_actions = vim.tbl_filter(function(action)
							return vim.startswith(action, "source.")
						end, client.server_capabilities.codeActionProvider.codeActionKinds)
						vim.lsp.buf.code_action({
							context = {
								only = source_actions,
							},
						})
					end, {})
				end,
			}

			--- @brief
			--- PHPActor is mainly a PHP Language Server with more features than you can shake a stick at
			--- https://github.com/phpactor/phpactor
			vim.lsp.config.phpactor = {
				cmd = { "phpactor", "language-server" },
				filetypes = { "php" },
				root_markers = { ".git", "composer.json", ".phpactor.json", ".phpactor.yml" },
				init_options = {
					["blackfire.enabled"] = false,
				},
				on_attach = function(client, bufnr)
					-- Helper function to create floating windows
					local function create_floating_window(title, syntax, contents)
						local lines = {}
						for line in string.gmatch(contents, "[^\n]+") do
							table.insert(lines, line)
						end

						local buf = vim.api.nvim_create_buf(false, true)
						vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
						vim.api.nvim_set_option_value("filetype", syntax, { buf = buf })

						local width = math.floor(vim.o.columns * 0.6)
						local height = math.floor(vim.o.columns * 0.4)
						local row = math.floor((vim.o.lines - height) / 2)
						local col = math.floor((vim.o.columns - width) / 2)

						local win = vim.api.nvim_open_win(buf, true, {
							relative = "editor",
							width = width,
							height = height,
							row = row,
							col = col,
							style = "minimal",
							border = "rounded",
							title = title,
						})

						-- Set keybinding to close window
						vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
						vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })

						return buf, win
					end

					-- PHPActor reindex function
					vim.lsp.buf_notify(bufnr, "workspace/executeCommand", {
						command = "phpactor/indexer/reindex",
						arguments = {},
					})

					-- PHPActor status (useful information and statistics)
					local results_status, _ = vim.lsp.buf_request_sync(bufnr, "phpactor/status", { ["return"] = true })
					for _, res in pairs(results_status or {}) do
						pcall(create_floating_window, "PHPActor Status", "markdown", res["result"])
					end

					-- PHPActor config dump
					local results_config, _ =
						vim.lsp.buf_request_sync(bufnr, "phpactor/debug/config", { ["return"] = true })
					for _, res in pairs(results_config or {}) do
						pcall(create_floating_window, "PHPActor LSP Configuration", "json", res["result"])
					end
				end,
				workspace_required = true,
			}

			---@brief
			--- Microsoft’s vscode-html-languageservice provides HTML language features
			--- with snippet-based completions and formatting support
			--- https://github.com/microsoft/vscode-html-languageservice
			vim.lsp.config.html = {
				cmd = { "vscode-html-language-server", "--stdio" },
				filetypes = { "html", "templ", "htmldjango" },
				root_markers = { "package.json", ".git" },
				settings = {},
				init_options = {
					provideFormatter = true,
					embeddedLanguages = { css = true, javascript = true },
					configurationSection = { "html", "css", "javascript" },
				},
			}

			---@brief
			--- Microsoft’s vscode-css-languageservice provides CSS language features
			--- with snippet-based completions and formatting support
			--- https://github.com/microsoft/vscode-css-languageservice
			vim.lsp.config.cssls = {
				cmd = { "vscode-css-language-server", "--stdio" },
				filetypes = { "css", "scss", "less" },
				init_options = { provideFormatter = true },
				root_markers = { "package.json", ".git" },
				settings = {
					css = { validate = true },
					scss = { validate = true },
					less = { validate = true },
				},
			}

      ---@brief
      --- A completion engine built from scratch for (La)TeX
      --- https://github.com/latex-lsp/texlab
      vim.lsp.config.texlab = {
        cmd = {' textlab '},
        filetypes = { 'tex', 'plaintex', 'bib' },
        root_markers = { '.git', '.latexmkrc', 'latexmkrc', '.texlabroot', 'texlabroot', 'Tectonic.toml'},
        settings = {
          texlab = {
            rootDirectory = nil,
            build = {
              executable = "latexmk",
              args = { '-pdf', '-interaction=nonstopmode', '-synctex=1', '%f' },
              onSave = false,
              forwardSearchAfter = false,
            },
            forwardSearch = {
              executable = nil,
              args = {},
            },
            chktex = {
              onOpenAndSave = false,
              onEdit = false,
            },
            diagnosticsDelay = 300,
            latexFormatter = 'latexindent',
            latexindent = {
              ['local'] = nil, --local is a reserved keyword
              modifyLineBreaks = false,
            },
            bibtexFormatter = 'texlab',
            formatterLineLength = 80,
          },
        },
        ---@param client vim.lsp.Client
        ---@param bufnr integer
        on_attach = function (client, bufnr)
          for _, cmd in ipairs({
            { name = 'TexlabBuild', fn = buf_latex_build, desc = "Build the current buffer"},
            { name = 'TexlabForward', fn = buf_latex_search, desc = "Forward search from current position"},
            { name = 'TexlabCancelBuild', fn = buf_latex_cancel_build, desc = "Cancel the current build"},
            { name = 'TexlabDependencyGraph', fn = dependency_latex_graph, desc = "Show the dependency graph"},
            { name = 'TexlabCleanArtifacts', fn = command_latex_factory('Artifacts'), desc = "Clean the artifacts"},
            { name = 'TexlabCleanAuxiliary', fn = command_latex_factory('Auxiliary'), desc = "Clean the auxiliary files"},
            { name = 'TexlabFindEnvironments', fn = buf_latex_find_envs, desc = "Find the environments at current position"},
            { name = 'TexlabChangeEnvironments', fn = buf_latex_change_env, desc = "Change the environment at current position"},
          }) do
            vim.api.nvim_buf_create_user_command(bufnr, 'Lsp' .. cmd.name, function()
              cmd.fn(client, bufnr)
            end, { desc = cmd.desc })
          end
        end
      }
		end,
	}, -- Completion engine
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
			{
				"brenoprata10/nvim-highlight-colors",
				config = true,
			},
		},
		config = function()
			local cmp = require("cmp")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Configure native LSP with enhanced capabilities
			-- En lugar de sobrescribir todo, configura cada LSP individualmente
			local servers = { "lua_ls", "clangd", "rust_analyzer", "gopls", "pyright", "ruby_lsp" }

			for _, server in ipairs(servers) do
				local config = vim.lsp.config[server] or {}
				config.capabilities = vim.tbl_deep_extend("force", config.capabilities or {}, capabilities)
				vim.lsp.config[server] = config
			end

			-- Load friendly snippets
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp", priority = 1000 },
					{ name = "luasnip", priority = 750 },
					{ name = "buffer", priority = 500 },
					{ name = "path", priority = 250 },
				}),
				format = require("nvim-highlight-colors").format,
			})
		end,
	}, -- Lua development enhancements
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = { library = { "luvit-meta/library" } },
		dependencies = { "Bilal2453/luvit-meta" },
	},
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>ff",
				function()
					require("conform").format({ async = true })
				end,
				mode = "",
				desc = "Format buffer",
			},
		},
		---@module "conform"
		---@type conform.setupOpts
		opts = {
			-- Formatters
			formatters_by_ft = {
				lua = { "stylua" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				go = { "goimports, gofumpt" },
				rust = { "rustfmt" },
				python = { "black", "isort" },
				ruby = { "rubocop" },
				javascript = { "prettierd" },
				typescript = { "prettierd" },
				json = { "prettierd" },
				yaml = { "prettierd" },
				markdown = { "prettierd" },
			},
			-- Default options
			default_format_opts = { lsp_format = "fallback" },
			-- Set up format-on-save
			format_on_save = { timeout_ms = 500 },
			-- Customize formatters
			formatters = {
				gofumpt = {
					args = { "$FILENAME" },
					stdin = false,
				},
			},
		},
	},
	-- Linter configuration!
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				lua = { "selene" },
				c = { "cpplint" },
				--cpp = { "cpplint" },
			}
			-- Create autocmd for linting
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
	{
		"rshkarin/mason-nvim-lint",
		dependencies = { "mason-org/mason.nvim", "mfussenegger/nvim-lint" },
		config = function()
			require("mason-nvim-lint").setup({
				ensure_installed = {
					"selene",
					--"cpplint",
				},
				automatic_installation = true,
				ignore_install = {},
				quiet_mode = false,
			})
		end,
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"jay-babu/mason-nvim-dap.nvim",
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
		},
		keys = {
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "Debug: Start/Continue",
			},
			{
				"<F1>",
				function()
					require("dap").step_into()
				end,
				desc = "Debug: Step Into",
			},
			{
				"<F2>",
				function()
					require("dap").step_over()
				end,
				desc = "Debug: Step Over",
			},
			{
				"<F3>",
				function()
					require("dap").step_out()
				end,
				desc = "Debug: Step Out",
			},
			{
				"<leader>b",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Debug: Toggle Breakpoint",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Debug: Toggle UI",
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- Setup DAP UI
			dapui.setup()

			-- Auto-open/close DAP UI
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end
		end,
	},

	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = { "mason-org/mason.nvim", "mfussenegger/nvim-dap" },
		config = function()
			require("mason-nvim-dap").setup({
				ensure_installed = { "debugpy" },
				automatic_installation = true,
				handlers = {}, -- Default configurations unless something is specified.
			})
		end,
	},
}
