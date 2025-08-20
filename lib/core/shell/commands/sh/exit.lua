--lib/core/shell/commands/sh/exit.lua

local exit = {}

function exit.execute(args, input_data, shell)
  return "exit"
end

return exit