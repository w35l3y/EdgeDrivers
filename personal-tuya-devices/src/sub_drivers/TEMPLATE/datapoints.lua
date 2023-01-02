local tuyaEF00_defaults = require "tuyaEF00_defaults"

return {
  ["manufacturer"] = { -- for example: _TZE200_1n2kyphz
    [1] = tuyaEF00_defaults.switch,
    [2] = tuyaEF00_defaults.switch,
    [3] = tuyaEF00_defaults.switch,
    [4] = tuyaEF00_defaults.switch,
  },
}