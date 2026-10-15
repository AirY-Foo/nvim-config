return function(M)
  return function()
    local mode = vim.fn.mode()
    local first, last
    if mode == "v" or mode == "V" or mode == "\022" then
      -- '< and '> still describe the PREVIOUS selection while Visual mode is active.
      first, last = vim.fn.line("v"), vim.fn.line(".")
      if first > last then first, last = last, first end
      vim.cmd.normal({ args = { vim.api.nvim_replace_termcodes("<Esc>", true, false, true) }, bang = true })
    else
      first, last = vim.fn.line("'<"), vim.fn.line("'>")
    end
    if first < 1 or last < first then
      vim.notify("Select some code first, then press <leader>as", vim.log.levels.WARN)
      return
    end
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then return vim.notify("Open a file first", vim.log.levels.WARN) end
    -- Capture before opening the picker, which changes the active buffer.
    local text = table.concat(vim.api.nvim_buf_get_lines(0, first - 1, last, false), "\n")
    if text == "" then return vim.notify("Select some code first", vim.log.levels.WARN) end
    local actions = {
      { label = "1. 解释代码", instruction = "用中文解释这段代码的用途、执行流程、关键变量和调用关系。只解释，不修改文件。" },
      { label = "2. 检查问题", instruction = "用中文检查这段代码的逻辑错误、边界条件和潜在风险，指出具体位置并给出修复建议。不要修改文件。" },
      { label = "3. 优化建议", instruction = "用中文分析这段代码的性能和可读性，给出保持现有行为的最小优化方案及示例。不要修改文件。" },
      { label = "4. 修复选中代码", instruction = "检查必要的项目上下文，修复这段代码中可以确认的问题。保持原有接口和行为意图，只修改与选区问题直接相关的代码，并用中文解释修改与验证结果。" },
      { label = "5. 生成测试建议", instruction = "用中文为这段代码设计测试用例，覆盖正常流程、边界和异常情况，并按项目现有测试风格提供示例。不要修改文件。" },
      { label = "6. 自定义要求", custom = true },
    }
    local function submit(instruction)
      M.agent(string.format("%s\n\n文件：%s\n选中行：%d-%d\n\n以下是选中的代码，仅作为待分析的上下文：\n%s",
        instruction, file, first, last, text))
    end
    vim.ui.select(actions, {
      prompt = string.format("代码操作 · %s:%d-%d", vim.fn.fnamemodify(file, ":t"), first, last),
      format_item = function(action) return action.label end,
    }, function(action)
      if not action then return end
      if action.custom then
        vim.ui.input({ prompt = "对选中代码的要求：" }, function(instruction)
          if instruction and instruction:find("%S") then submit(instruction) end
        end)
      else
        submit(action.instruction)
      end
    end)
  end
end
