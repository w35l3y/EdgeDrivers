-- local log = require "log"
-- local utils = require "st.utils"

local capabilities = require "st.capabilities"

local debug = capabilities["valleyboard16460.debug"]
local myutils = require "utils"

return {
  NAME = "Debug",
  can_handle = function (opts, driver, device, ...)
    return device:supports_capability_by_id(debug.ID)
  end,
  supported_capabilities = {
    capabilities.refresh,
    debug,
  },
  lifecycle_handlers = {
    init = function (driver, device, ...)
      driver:call_with_delay(0, function ()
        device:emit_event(debug.value(tostring(myutils.debug(device))))
      end)
    end,
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = function (driver, device, ...)
        device:emit_event(debug.value(tostring(myutils.debug(device)), { visibility = { displayed = false } }))
      end
    }
    -- [info.ID] = {
    --   [info.commands.clear.NAME] = function (driver, device, ...)
    --     device:emit_event(info.value(tostring(myutils.info(device)), { visibility = { displayed = false } }))
    --   end
    -- },
  },
}