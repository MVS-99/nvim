return {
    -- Treesitter is a parser generator tool
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        lazy = false,
        branch = 'main',
        event = {'BufReadPost', 'BufNewFile'},
        cmd = {'TSUpdateSync', 'TSUpdate', 'TSInstall'},
        config = function()
            require('nvim-treesitter').setup({
                -- Essential parsers for Neovim functionality
                ensure_installed = {
                    'c', -- Core Neovim functionality
                    'lua', -- Neovim configuration
                    'luadoc', -- Lua documentation (@module, @type annotations)
                    'vim', -- Vim script files
                    'vimdoc', -- Vim help files
                    'query' -- Treesitter queries
                },

                -- Install parsers synchronously (only applied to ensure_installed)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                auto_install = false,

                -- Core modules
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false
                },

                indent = {enable = true},

                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = '<C-space>',
                        node_incremental = '<C-space>',
                        scope_incremental = false,
                        node_decremental = '<bs>'
                    }
                }
            })
        end
    }
}
