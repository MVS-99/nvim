return{
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = function()
    require('dashboard').setup{
        theme = 'hyper', --  theme is doom and hyper default is hyper
        disable_move = true,   --  default is false disable move keymap for hyper
        shortcut_type = "letter",   --  shorcut type 'letter' or 'number'
        change_to_vcs_root = false,-- default is false,for open file in hyper mru. it will change to the root of vcs
        config = {
          header = {
            '',
            '              ...                            ',
            '             ;::::;                           ',
            '           ;::::; :;                          ',
            '         ;:::::\'   :;                         ',
            '        ;:::::;     ;.                        ',
            '       ,:::::\'       ;           OOO\\         ',
            '       ::::::;       ;          OOOOO\\        ',
            '       ;:::::;       ;         OOOOOOOO       ',
            '      ,;::::::;     ;\'         / OOOOOOO      ',
            '    ;:::::::::`. ,,,;.        /  / DOOOOOO    ',
            '  .\';:::::::::::::::::;,     /  /     DOOOO   ',
            ' ,::::::;::::::;;;;::::;,   /  /        DOOO  ',
            ';`::::::`\'::::::;;;::::: ,#/  /          DOOO ',
            ':`:::::::`;::::::;;::: ;::#  /            DOOO',
            '::`:::::::`;:::::::: ;::::# /              DOO',
            '`:`:::::::`;:::::: ;::::::#/               DOO',
            ' :::`:::::::`;; ;:::::::::##                OO',
            ' ::::`:::::::`;::::::::;:::#                OO',
            ' `:::::`::::::::::::;\'`:;::#                O ',
            '  `:::::`::::::::;\' /  / `:#                  ',
            '',
          },
          week_header = {
            enable = false
          },
          shortcut = {
            { desc = '󰚰 Update', group = '@property', action = 'Lazy update', key = 'u' },
            {
                icon = ' ',
                icon_hl = '@float',
                desc = 'Files',
                group = '@float',
                action = 'Telescope find_files',
                key = 'f',
            },
            {
                desc = ' Configuration',
                group = 'Question',
                action = ':Neotree ~/.config/nvim/',
                key = 'c',
            },
          },
          packages = { enable = true}, -- show how many plugins neovim has loaded
          project = { enable = true, limit = 10, icon = "", action = "Telescope find_files cwd="},
          footer = {' 󱢿 Nihil Prius Fide'}
        },    --  config used for theme
      hide = {
        statusline = true,    -- hide statusline default is true
        tabline = true,       -- hide the tabline
        winbar = true,       -- hide winbar
      },
    }
  end,
}
