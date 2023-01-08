local tuyaEF00_defaults = require "tuyaEF00_defaults"

return {
  ["manufacturer"] = { -- for example: _TZE200_1n2kyphz
    [1] = tuyaEF00_defaults.switch({group=1}),
    [2] = tuyaEF00_defaults.switch({group=2}),
    [3] = tuyaEF00_defaults.switch({group=3}),
    [4] = tuyaEF00_defaults.switch({group=4}),
  },
}