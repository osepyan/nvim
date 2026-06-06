vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- increment / decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

-- ============================================================
-- 1C initial_data transformations
-- ============================================================

-- Шаг 1: initial_data (JSON) → DTO
-- Активный буфер: initial_data файл
local fng_pattern = [[{"Имя": "\([^"]*\)", "НовоеИмя":[ ]*"\([^"]*\)"}]]

keymap.set("n", "<leader>1d", function()
  vim.cmd([[%s/]] .. fng_pattern .. [[/\2: str | None = None/]])
end, { desc = "1C → DTO (все поля str)" })

-- ============================================================

-- Шаг 3: DTO (с исправленными типами) → SQLAlchemy таблица
-- Активный буфер: скорректированный DTO

local function dto_to_column()
  vim.cmd([[%s/\(\w\+\): str | None = None/\1 = Column(String, nullable=True, default=None)/]])
  vim.cmd([[%s/\(\w\+\): datetime | None = None/\1 = Column(DateTime, nullable=True, default=None)/]])
  vim.cmd([[%s/\(\w\+\): bool | None = None/\1 = Column(Boolean, nullable=True, default=None)/]])
  vim.cmd([[%s/\(\w\+\): int | None = None/\1 = Column(Integer, nullable=True, default=None)/]])
  vim.cmd([[%s/\(\w\+\): float | None = None/\1 = Column(Float, nullable=True, default=None)/]])
end

keymap.set("n", "<leader>2c", dto_to_column, { desc = "DTO → SQLAlchemy Column" })

-- ============================================================

-- Шаг 4: DTO (с исправленными типами) + initial_data → mapper
-- Активный буфер: скорректированный DTO
-- Требует открытый буфер с initial_data (по имени файла)

local function merge_mapper()
  -- 1. Найти буфер initial_data
  local initial_buf = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match("initial_data") then
      initial_buf = buf
      break
    end
  end

  if not initial_buf then
    vim.notify("Буфер 'initial_data' не найден — откройте файл", vim.log.levels.ERROR)
    return
  end

  -- 2. initial_data → { domain_name: fng_path }
  local fng_map = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(initial_buf, 0, -1, false)) do
    local path, name = line:match('"Имя": "([^"]+)".-"НовоеИмя":%s*"([^"]+)"')
    if name then
      fng_map[name] = path
    end
  end

  -- 3. DTO (текущий буфер) → { domain_name: type_hint }, порядок сохраняем
  local type_map = {}
  local order = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local domain_name, type_hint = line:match("^([%w_]+): (%w+) | None = None")
    if domain_name then
      type_map[domain_name] = type_hint
      table.insert(order, domain_name)
    end
  end

  -- 4. Собрать результат
  local result = {}
  for _, domain_name in ipairs(order) do
    table.insert(
      result,
      string.format(
        "_m(domain_name='%s', fng_path='%s', type_hint=%s),",
        domain_name,
        fng_map[domain_name] or "",
        type_map[domain_name] or "str"
      )
    )
  end

  -- 5. Открыть новый буфер с результатом
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, result)
end

keymap.set("n", "<leader>2m", merge_mapper, { desc = "DTO + initial_data → mapper" })
