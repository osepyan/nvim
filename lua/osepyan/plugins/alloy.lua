return {
  "grafana/vim-alloy",
  ft = "alloy", -- lazy-load только для Alloy
  init = function()
    -- Регистрируем filetype ДО загрузки плагина
    vim.filetype.add({
      extension = {
        alloy = "alloy",
      },
    })
  end,
}
