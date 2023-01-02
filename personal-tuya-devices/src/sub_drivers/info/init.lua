--local log = require "log"
--local utils = require "st.utils"

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
      --if device.zigbee_endpoints ~= nil then
        device:emit_component_event({id="main"}, info.value(tostring(myutils.info(device))))
      --end
    end,
  },
}