local tuyaEF00_defaults = require "tuyaEF00_defaults"
local REPORT_BY_DP = require "sub_drivers.TS0601.datapoints"

local defaults = {
  lifecycle_handlers = require "lifecycles"
}

function defaults.can_handle (model)
  return function (opts, driver, device, ...)
    if device:get_model() == model then
      for mfr,dp in pairs(REPORT_BY_DP) do
        if mfr == device:get_manufacturer() then
          return true
        end
      end
    end
    return false
  end
end

local function send_command(fn, driver, device, ...)
  local datapoints = REPORT_BY_DP[device:get_manufacturer()]
  if datapoints ~= nil then
    fn(datapoints)(driver, device, ...)
  end
end

function defaults.command_data_report_handler(...)
  send_command(tuyaEF00_defaults.command_data_report_handler, ...)
end

function defaults.command_on_handler(...)
  send_command(tuyaEF00_defaults.command_on_handler, ...)
end

function defaults.command_off_handler(...)
  send_command(tuyaEF00_defaults.command_off_handler, ...)
end

function defaults.command_open_handler(...)
  send_command(tuyaEF00_defaults.command_open_handler, ...)
end

function defaults.command_close_handler(...)
  send_command(tuyaEF00_defaults.command_close_handler, ...)
end

function defaults.command_level_handler(...)
  send_command(tuyaEF00_defaults.command_level_handler, ...)
end

return defaults