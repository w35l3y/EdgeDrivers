local commands = require "commands"

return {
  ["manufacturer"] = { -- for example: _TZE200_1n2kyphz
    [1] = commands.switch({group=1}),
    [2] = commands.switch({group=2}),
    [3] = commands.switch({group=3}),
    [4] = commands.switch({group=4}),
  },
}