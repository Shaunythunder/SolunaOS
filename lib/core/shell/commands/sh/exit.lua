--lib/core/shell/commands/sh/exit.lua

local exit = {}
exit.description = "Exits the shell"
exit.usage = "Usage: exit"
exit.flags = {}

  function exit.execute(args, input_data, shell)
    if #args > 0 then
        return exit.usage
    end
    return "exit"
  end

return exit