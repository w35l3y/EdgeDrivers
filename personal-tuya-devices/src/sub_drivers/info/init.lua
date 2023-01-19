-- local log = require "log"
-- local utils = require "st.utils"

local capabilities = require "st.capabilities"

local info = capabilities["valleyboard16460.info"]
local myutils = require "utils"

return {
  NAME = "Info",
  can_handle = function (opts, driver, device, ...)
    return device:supports_capability_by_id(info.ID)
  end,
  supported_capabilities = {
    info,
  },
  lifecycle_handlers = {
    added = function (driver, device, ...)
      device:emit_event(info.value(tostring(myutils.info(device))))
    end,
  },
  capability_handlers = {
    -- [info.ID] = {
    --   [info.commands.clear.NAME] = function (driver, device, ...)
    --     device:emit_event(info.value(tostring(myutils.info(device)), { visibility = { displayed = false } }))
    --   end
    -- },
  },
}