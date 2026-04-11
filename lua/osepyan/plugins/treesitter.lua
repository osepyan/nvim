return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    local parsers = {
      "json",
      "javascript",
      "typescript",
      "tsx",
      "yaml",
      "toml",
      "xml",
      "html",
      "css",
      "markdown",
      "markdown_inline",
      "graphql",
      "bash",
      "lua",
      "vim",
      "dockerfile",
      "gitignore",
      "query",
      "vimdoc",
      "python",
      "csv",
    }
    require("nvim-treesitter").install(parsers)

    -- nvim-treesitter v1.0 не настраивает подсветку автоматически.
    -- Включаем через встроенный Neovim API на каждый FileType.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
      end,
    })

    require("nvim-ts-autotag").setup()
  end,
}
