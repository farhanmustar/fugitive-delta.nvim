if vim.fn.exists("g:loaded_fugitive_delta") ~= 0 then
  return
end
vim.g.loaded_fugitive_delta = 1

if vim.fn.executable("delta") ~= 1 then
  return
end
local M = {}

local fugitive_delta_group = vim.api.nvim_create_augroup("fugitive_delta_group", { clear = true })
local hi_ns = vim.api.nvim_create_namespace("fdhi")
local hi_opts = {
  priority=300
}
local hi_group = "FugitiveDeltaText"
vim.api.nvim_command("highlight link FugitiveDeltaText DiffText")

M.filetype_cb = function ()
  -- initial setup
  if vim.b.fugitive_delta ~= nil then
    return
  end
  vim.b.fugitive_delta = 1
  vim.b.fugitive_delta_lines = {}

  local buf = vim.fn.bufnr("%")
  local output_lines = vim.fn.systemlist({"delta", "--paging=never", "--diff-highlight"}, buf)
  vim.b.fugitive_delta_output = output_lines
  -- TODO: handle command error out.

  local fugitive_delta_buf_group = vim.api.nvim_create_augroup("fugitive_delta_buf_group", { clear = false })
  vim.api.nvim_clear_autocmds({ buffer = buf, group = fugitive_delta_buf_group })
  M.move_cb()
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = M.move_cb,
    group = fugitive_delta_buf_group,
  })
end

M.move_cb = function ()
  local line_start = vim.fn.line("w0")
  local line_end = vim.fn.line("w$")
  local max_line = vim.fn.line("$")

  line_start = line_start < 1 and 1 or line_start
  line_end = line_end > max_line and max_line or line_end

  if line_end - line_start < 1 then
    return
  end

  if vim.b.fugitive_delta_start ~= line_start or vim.b.fugitive_delta_end ~= line_end then
    vim.b.fugitive_delta_start = line_start
    vim.b.fugitive_delta_end = line_end
    local buf = vim.fn.bufnr("%")
    M.highlight_visible(buf, line_start, line_end)
  end

end

function M.get_hi_group(ansi)
  return vim.fn.matchstr(ansi, "\\d\\zem")
end

M.highlight_visible = function (buf, line_start, line_end)
  for i = line_start, line_end do
    if vim.b.fugitive_delta_lines[i] then
      goto continue
    end
    vim.b.fugitive_delta_lines[i] = true
    local l = vim.b.fugitive_delta_output[i]
    local _, hi_list = M.highlight_line(l)
    for _, v in ipairs(hi_list) do
      local prefix, col_s, col_e = v[1], v[2], v[3]
      if prefix == "7" then
        -- col + 1 due to delta not having the + indicator
        vim.highlight.range(buf, hi_ns, hi_group, {i - 1, col_s + 1}, {i - 1, col_e + 1}, hi_opts)
        -- vim.print(prefix.." "..col_s.." "..col_e)
      end
    end
    ::continue::
  end
end

function M.highlight_line(l)
  local prev_hi = ""
  local prev_idx = ""
  local hi_list = {}

  local m, e
  local s = 0
  while true do
    m, s, e = unpack(vim.fn.matchstrpos(l, "\\e\\[[0-9;]*[mK]", s))
    if #m == 0 then
      break
    end
    if s == 0 then
      l = l:sub(e + 1)
    else
      l = l:sub(1, s) .. l:sub(e + 1)
    end

    local cur_hi = M.get_hi_group(m)
    if prev_hi == cur_hi then
      goto continue
    end

    if #prev_hi > 0 then
      table.insert(hi_list, {prev_hi, prev_idx, s})
    end

    prev_hi = cur_hi
    prev_idx = s
    ::continue::
  end
  return l, hi_list
end


vim.api.nvim_create_autocmd("FileType", {
  pattern = "git,diff",
  callback = M.filetype_cb,
  group = fugitive_delta_group,
})