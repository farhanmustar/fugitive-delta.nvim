if vim.fn.exists("g:loaded_fugitive_delta") ~= 0 then
  return
end
vim.g.loaded_fugitive_delta = 1

if vim.fn.executable("delta") ~= 1 then
  return
end
local M = {}
M.fugitive_delta_lines = {}

local fugitive_delta_group = vim.api.nvim_create_augroup("fugitive_delta_group", { clear = true })
local hi_ns = vim.api.nvim_create_namespace("fdhi")
local hi_opts = {
  priority=300
}
local hi_group = "FugitiveDeltaText"
vim.api.nvim_command("highlight link FugitiveDeltaText DiffText")

vim.api.nvim_create_autocmd("BufWipeout", {
  callback = function(args)
    M.fugitive_delta_lines[args.buf] = nil
  end,
  group = fugitive_delta_group,
})

M.filetype_cb = function ()
  -- initial setup
  if vim.b.fugitive_delta ~= nil then
    return
  end
  vim.b.fugitive_delta = 1

  local buf = vim.fn.bufnr("%")
  M.fugitive_delta_lines[buf] = {}
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
  vim.api.nvim_create_autocmd({"BufDelete", "BufUnload"}, {
    buffer = buf,
    callback = function()
      vim.api.nvim_clear_autocmds({ buffer = buf, group = fugitive_delta_buf_group })
    end,
    group = fugitive_delta_buf_group,
  })
end

M.move_cb = function ()
  local line_start = vim.fn.line("w0")
  local line_end = vim.fn.line("w$")
  local max_line = vim.fn.line("$")

  line_start = line_start < 1 and 1 or line_start
  -- add +1 to line end due to w$ not getting the overflow line.
  line_end = line_end + 1 > max_line and max_line or line_end + 1

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
  return vim.fn.matchstr(ansi, "[0-9;]\\+\\zem")
end

M.highlight_visible = function (buf, line_start, line_end)
  for i = line_start, line_end do
    if M.fugitive_delta_lines[buf][i] then
      goto continue
    end
    M.fugitive_delta_lines[buf][i] = true
    local l = vim.b.fugitive_delta_output[i]
    local _, hi_list = M.highlight_line(l)
    for _, v in ipairs(hi_list) do
      local prefix, col_s, col_e = v[1], v[2], v[3]
      if prefix == "7" or M.startswith(prefix, "7;") then
        if col_s ~= col_e then
          -- col + 1 due to delta not having the + indicator
          vim.highlight.range(buf, hi_ns, hi_group, {i - 1, col_s + 1}, {i - 1, col_e + 1}, hi_opts)
        end
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

function M.startswith(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "git,diff",
  callback = M.filetype_cb,
  group = fugitive_delta_group,
})

-- fugitive summary buffer modification
M.summary_cb = function ()
  if vim.b.fugitive_delta ~= nil then
    return
  end
  vim.b.fugitive_delta = 1
  local buf = vim.fn.bufnr("%")
  local fugitive_delta_summary_buf_group =
    vim.api.nvim_create_augroup("fugitive_delta_summary_buf_group", { clear = false })
  vim.api.nvim_clear_autocmds({ buffer = buf, group = fugitive_delta_summary_buf_group })
  vim.api.nvim_create_autocmd("TextChanged", {
    buffer = buf,
    callback = M.summary_updated_cb,
    group = fugitive_delta_summary_buf_group,
  })
  vim.api.nvim_create_autocmd({"BufDelete", "BufUnload"}, {
    buffer = buf,
    callback = function()
      vim.api.nvim_clear_autocmds({ buffer = buf, group = fugitive_delta_summary_buf_group })
    end,
    group = fugitive_delta_summary_buf_group,
  })
  M.summary_updated_cb()
end

vim.api.nvim_create_autocmd("User", {
  pattern = "FugitiveIndex",
  callback = M.summary_cb,
  group = fugitive_delta_group,
})

M.summary_updated_cb = function ()
  local buf = vim.fn.bufnr("%")
  M.fugitive_delta_lines[buf] = {}
  vim.b.fugitive_delta_start = nil
  vim.b.fugitive_delta_end = nil
  local output_lines = vim.fn.systemlist({"delta", "--paging=never", "--diff-highlight"}, buf)
  vim.b.fugitive_delta_output = output_lines
  -- TODO: handle command error out.

  vim.api.nvim_buf_clear_namespace(buf, hi_ns, 0, -1)
  local fugitive_delta_summary_move_group =
    vim.api.nvim_create_augroup("fugitive_delta_summary_move_group", { clear = false })
  vim.api.nvim_clear_autocmds({ buffer = buf, group = fugitive_delta_summary_move_group })
  M.move_cb()
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = M.move_cb,
    group = fugitive_delta_summary_move_group,
  })
  vim.api.nvim_create_autocmd({"BufDelete", "BufUnload"}, {
    buffer = buf,
    callback = function()
      vim.api.nvim_clear_autocmds({ buffer = buf, group = fugitive_delta_summary_move_group })
    end,
    group = fugitive_delta_summary_move_group,
  })
end
