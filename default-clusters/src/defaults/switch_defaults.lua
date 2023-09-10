local zcl_clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"

local OnOff = zcl_clusters.OnOff

function OnOff.server_id_map()
  return {
    [0x00] = "Off",
    [0x01] = "On",
    [0x02] = "Toggle",
    [0x40] = "OffWithEffect",
    [0x41] = "OnWithRecallGlobalScene",
    [0x42] = "OnWithTimedOff",
    [0xFD] = "ButtonPress",
  }
end

OnOff.command_direction_map["ButtonPress"] = "server"

-- local Status = require "st.zigbee.generated.types.ZclStatus"
local switch_defaults = require "st.zigbee.defaults.switch_defaults"

-- function switch_defaults.default_response_handler(driver, device, zb_rx)
--   local status = zb_rx.body.zcl_body.status.value

--   if status == Status.SUCCESS then
--     local cmd = zb_rx.body.zcl_body.cmd.value
--     local event = nil

--     if cmd == zcl_clusters.OnOff.server.commands.On.ID then
--       event = capabilities.switch.switch.on()
--     elseif cmd == zcl_clusters.OnOff.server.commands.Off.ID then
--       event = capabilities.switch.switch.off()
--     end

--     if event ~= nil then
--       device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, event)
--     end
--   end
-- end

function switch_defaults.button_pressed_handler(driver, device, zb_rx)
  local button_status = zb_rx.body.zcl_body.button_status.value
  local ButtonStatus = require "st.zigbee.generated.zcl_clusters.OnOff.types.ButtonStatus"
  local STATUS = {
    [ButtonStatus.PUSHED] = capabilities.button.button.pushed(),
    [ButtonStatus.DOUBLE] = capabilities.button.button.double(),
    [ButtonStatus.HELD]   = capabilities.button.button.held(),
  }
  local event = STATUS[button_status]
  if (event ~= nil) then
    device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, event)
  end
end

switch_defaults.zigbee_handlers.cluster[zcl_clusters.OnOff.ID] = {
  [zcl_clusters.OnOff.server.commands.ButtonPress.ID] = switch_defaults.button_pressed_handler
}

return switch_defaults