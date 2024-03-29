return {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v3.x',
  dependencies = {
    -- LSP Support
    {'neovim/nvim-lspconfig'},
    {'lvimuser/lsp-inlayhints.nvim'},
    {'mrcjkb/rustaceanvim',
      version = '^4', --Recommended
      ft = { 'rust' },
    },
    {'williamboman/mason.nvim'},
    {'williamboman/mason-lspconfig.nvim'},
    {'SmiteshP/nvim-navic'},
    -- Autocompletion
    {'hrsh7th/nvim-cmp'},     -- Required
    {'hrsh7th/cmp-nvim-lsp'}, -- Required
    {'hrsh7th/cmp-buffer'},
    {'hrsh7th/cmp-path'},
    {'L3MON4D3/LuaSnip',
      dependencies = {'rafamadriz/friendly-snippets'}
    },     -- Required
  },
  config = function()
    local lsp_zero = require('lsp-zero')

    lsp_zero.on_attach(function(client, bufnr)
      local opts = {buffer = bufnr, remap = false}

      vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
      vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
      vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
      vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
      vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
      vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
      vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
      vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
      vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
      vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)

      if client.server_capabilities.documentSymbolProvider then
        require('nvim-navic').attach(client, bufnr)
      end

    end)

    vim.g.rustaceanvim = {
      server = {
        capabilities = lsp_zero.get_capabilities()
      }
    }

    -- Set navic highlight groups
    vim.api.nvim_set_hl(0, "NavicIconsFile",          {default = true, bg = "#282828", fg = "#EBDBB2"})
    vim.api.nvim_set_hl(0, "NavicIconsModule",        {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsNamespace",     {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsPackage",       {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsClass",         {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsMethod",        {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsProperty",      {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsField",         {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsConstructor",   {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsEnum",          {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsInterface",     {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsFunction",      {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsVariable",      {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsConstant",      {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsString",        {default = true, bg = "#282828", fg = "#D3869B"})
    vim.api.nvim_set_hl(0, "NavicIconsNumber",        {default = true, bg = "#282828", fg = "#8F3F71"})
    vim.api.nvim_set_hl(0, "NavicIconsBoolean",       {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsArray",         {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsObject",        {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsKey",           {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsNull",          {default = true, bg = "#282828", fg = "#928374"})
    vim.api.nvim_set_hl(0, "NavicIconsEnumMember",    {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsStruct",        {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsEvent",         {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsOperator",      {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicIconsTypeParameter", {default = true, bg = "#282828", fg = "#83A598"})
    vim.api.nvim_set_hl(0, "NavicText",               {default = true, bg = "#282828", fg = "#EBDBB2"})
    vim.api.nvim_set_hl(0, "NavicSeparator",          {default = true, bg = "#282828", fg = "#504945"})
    require('nvim-navic').setup({
      highlight = true,
    })

    require('mason').setup({})
    require('mason-lspconfig').setup({
      ensure_installed = {},
      handlers = {
        lsp_zero.default_setup,
        rust_analyzer = lsp_zero.noop,
        lua_ls = function()
          local lua_opts = lsp_zero.nvim_lua_ls()
          require('lspconfig').lua_ls.setup(lua_opts)
        end,
      }
    })

    local cmp = require('cmp')
    local cmp_select = {behavior = cmp.SelectBehavior.Select}

    require('luasnip.loaders.from_vscode').lazy_load()

    cmp.setup({
      sources = {
        {name = 'path'},
        {name = 'nvim_lsp'},
        {name = 'nvim_lua'},
        {name = 'luasnip', keyword_length = 2},
        {name = 'buffer', keyword_length = 3},
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      formatting = lsp_zero.cmp_format(),
      mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
      }),
    })
  end,
}
