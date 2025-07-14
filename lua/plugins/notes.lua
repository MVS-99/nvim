return
{
  {"vhyrro/luarocks.nvim",
    priority = 1001,
    config = true,
    opts = {
      rocks = { "magick" },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
  }
}
