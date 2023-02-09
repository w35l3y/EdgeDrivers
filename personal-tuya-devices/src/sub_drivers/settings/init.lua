--local log = require "log"
--local utils = require "st.utils"

local capabilities = require "st.capabilities"

local settings = capabilities["valleyboard16460.settings"]
local myutils = require "utils"

return {
  NAME = "Settings",
  can_handle = function (opts, driver, device, ...)
    return device:supports_capability_by_id(settings.ID)
  end,
  supported_capabilities = {
    settings,
  },
  lifecycle_handlers = {
    added = function (driver, device, ...)
      -- driver:call_with_delay(0, function ()
      device:emit_event(settings.value(tostring(myutils.settings(device))))
      -- end)
    end,
  },
}