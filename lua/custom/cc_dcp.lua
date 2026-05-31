-- Dynamic Context Pruning for CodeCompanion
-- Three zero-LLM-cost strategies:
--   1. Deduplication    — identical tool call+result pairs: keep only the latest
--   2. Error purging    — failed tool results older than PROTECT_TURNS cycles
--   3. File supersede   — any file tool op is stale if the same path was touched again later
--                         (covers re-reads at different line ranges, edit→re-read, etc.)
-- Turn protection always guards the most recent PROTECT_TURNS cycles.

-- Protect the most recent N cycles from pruning.
-- 1 = protect only the last user turn (good for manual /prune).
-- Raise to 2+ if you want to keep more recent history safe.
local PROTECT_TURNS = 1

-- All tools that operate on a specific file path (read OR write).
-- Any earlier call on a filepath is superseded by a later call on the same filepath.
-- Configurable: add MCP tool names here if they use PATH_FIELD in their input.
local FILE_TOOLS = {
  read_file = true,
  insert_edit_into_file = true,
  create_file = true,
  write_file = true,
  edit_file = true,
}

-- Input field that holds the file path for the tools above.
local PATH_FIELD = 'filepath'

-- ---------------------------------------------------------------------------

local function resolve_call(call)
  -- OpenAI/DeepSeek format: call["function"].name + call["function"].arguments (JSON string)
  -- Claude format: call.name + call.input (table)
  local fn = call["function"]
  if fn and fn.name then
    local input = nil
    if fn.arguments then
      local ok, decoded = pcall(vim.json.decode, fn.arguments)
      if ok then input = decoded end
    end
    return fn.name, input
  end
  return call.name, call.input
end

local function tool_key(name, input)
  local ok, encoded = pcall(vim.json.encode, input or {})
  return name .. '|' .. (ok and encoded or tostring(input))
end

local function is_error_output(content)
  if type(content) ~= 'string' then return false end
  local c = content:lower()
  return c:find 'error:' ~= nil
    or c:find 'exception:' ~= nil
    or c:find 'traceback' ~= nil
    or c:find 'command failed' ~= nil
    or c:find 'exit code [1-9]' ~= nil
    or c:find 'exit status [1-9]' ~= nil
end

---@class CodeCompanion.SlashCommand.DCP: CodeCompanion.SlashCommand
local SlashCommand = {}

function SlashCommand.new(args)
  return setmetatable({
    Chat = args.Chat,
    config = args.config,
    context = args.context,
  }, { __index = SlashCommand })
end

function SlashCommand:execute(_)
  local chat = self.Chat
  local messages = chat.messages
  local current_cycle = chat.cycle

  -- Phase 1: index call/result pairs
  -- call_info[call_id]    = { msg_i, name, input, key, cycle }
  -- result_info[call_id]  = { msg_i, cycle }
  -- dedup[key]            = ordered list of call_ids (for exact-match dedup)
  -- last_file_op[fp]      = latest cycle any FILE_TOOL operated on that filepath
  local call_info = {}
  local result_info = {}
  local dedup = {}
  local last_file_op = {}

  for i, msg in ipairs(messages) do
    local cycle = msg._meta and msg._meta.cycle or 0
    if msg.tools and msg.tools.calls then
      for _, call in ipairs(msg.tools.calls) do
        if call.id then
          local name, input = resolve_call(call)
          if name then
            local k = tool_key(name, input)
            call_info[call.id] = { msg_i = i, name = name, input = input, key = k, cycle = cycle }
            dedup[k] = dedup[k] or {}
            table.insert(dedup[k], call.id)

            if FILE_TOOLS[name] then
              local fp = type(input) == 'table' and input[PATH_FIELD]
              if fp and (not last_file_op[fp] or cycle > last_file_op[fp]) then
                last_file_op[fp] = cycle
              end
            end
          end
        end
      end
    end
    if msg.tools and msg.tools.call_id then
      result_info[msg.tools.call_id] = { msg_i = i, cycle = cycle }
    end
  end

  -- Phase 2: decide what to remove
  local to_remove = {}
  local stats = { dedup = 0, errors = 0, supersede = 0 }

  -- Deduplication: keep only the most recent call per exact tool+input combo
  for _, ids in pairs(dedup) do
    if #ids > 1 then
      for i = 1, #ids - 1 do
        local info = call_info[ids[i]]
        if info and (current_cycle - info.cycle) > PROTECT_TURNS then
          to_remove[ids[i]] = true
          stats.dedup = stats.dedup + 1
        end
      end
    end
  end

  -- Error purging
  for call_id, rinfo in pairs(result_info) do
    if not to_remove[call_id] and (current_cycle - rinfo.cycle) > PROTECT_TURNS then
      local msg = messages[rinfo.msg_i]
      if msg and is_error_output(msg.content) then
        to_remove[call_id] = true
        stats.errors = stats.errors + 1
      end
    end
  end

  -- File supersede: any file op is stale if the same path was touched in a later cycle
  for call_id, info in pairs(call_info) do
    if not to_remove[call_id] and FILE_TOOLS[info.name] then
      local fp = type(info.input) == 'table' and info.input[PATH_FIELD]
      if fp then
        local latest = last_file_op[fp]
        if latest and latest > info.cycle and (current_cycle - info.cycle) > PROTECT_TURNS then
          to_remove[call_id] = true
          stats.supersede = stats.supersede + 1
        end
      end
    end
  end

  -- Debug: summarise what was indexed
  local pair_count = vim.tbl_count(call_info)
  local cycle_set = {}
  for _, info in pairs(call_info) do cycle_set[info.cycle] = true end
  local cycles = vim.tbl_keys(cycle_set)
  table.sort(cycles)
  local debug_msg = ('[DCP] %d tool pairs across cycles %s (current=%d, protecting >%d)'):format(
    pair_count,
    table.concat(cycles, ','),
    current_cycle,
    current_cycle - PROTECT_TURNS - 1
  )

  if vim.tbl_isempty(to_remove) then
      vim.notify(debug_msg .. '\nNothing to prune', vim.log.levels.INFO)
    return
  end

  vim.notify(debug_msg, vim.log.levels.INFO)

  -- Phase 3: rebuild message list
  local new_messages = {}
  for _, msg in ipairs(messages) do
    if msg.tools and msg.tools.call_id then
      if not to_remove[msg.tools.call_id] then
        table.insert(new_messages, msg)
      end
    elseif msg.tools and msg.tools.calls then
      local filtered = vim.tbl_filter(function(c) return not to_remove[c.id] end, msg.tools.calls)
      local has_text = type(msg.content) == 'string' and msg.content ~= ''
      if #filtered > 0 or has_text then
        if #filtered ~= #msg.tools.calls then
          msg = vim.tbl_extend('force', {}, msg)
          msg.tools = vim.tbl_extend('force', {}, msg.tools)
          msg.tools.calls = filtered
        end
        table.insert(new_messages, msg)
      end
    else
      table.insert(new_messages, msg)
    end
  end

  chat.messages = new_messages

  vim.notify(
    ('[DCP] Pruned %d pair(s) — %d dedup, %d error, %d file-supersede'):format(
      stats.dedup + stats.errors + stats.supersede,
      stats.dedup, stats.errors, stats.supersede
    ),
    vim.log.levels.INFO
  )
end

return SlashCommand
