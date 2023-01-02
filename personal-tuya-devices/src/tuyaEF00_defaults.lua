local log = require "log"
local utils = require "st.utils"

local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"
local generic_body = require "st.zigbee.generic_body"

local myutils = require "utils"

local defaults = {}

local function to_number (value)
  if type(value) == "boolean" then
    return value and 1 or 0
  elseif type(value) == "string" then
    return tonumber(value, 10)
  elseif type(value) == "nil" then
    return 0
  end
  return value
end

function defaults.on_off(value)
  local attr = capabilities.switch.switch
  return value and attr.on() or attr.off()
end

function defaults.level(value)
  return capabilities.switchLevel.level(math.floor(to_number(value) / 10))
  --return capabilities.switchLevel.level(math.floor((value.value / 254.0 * 100) + 0.5))
end

function defaults.open_close(value)
  --log.info(utils.stringify_table(capabilities.doorControl, "doorControl", true))
  return capabilities.doorControl.door(value and "open" or "closed")
end

function defaults.open_closed(value)
  return capabilities.contactSensor.contact(value and "open" or "closed")
end

function defaults.enum(value)
  return capabilities["valleyboard16460.datapointEnum"].value(to_number(value))
end

function defaults.string(value)
  return capabilities["valleyboard16460.datapointString"].value(tostring(value))
end

function defaults.raw(value)
  return capabilities["valleyboard16460.datapointRaw"].value(value)
end

function defaults.value(value)
  return capabilities["valleyboard16460.datapointValue"].value(to_number(value))
end

function defaults.bitmap(value)
  return capabilities["valleyboard16460.datapointBitmap"].value(to_number(value))
end

local map_to_fn = {
  [tuya_types.DatapointSegmentType.BOOLEAN] = defaults.on_off,
  [tuya_types.DatapointSegmentType.VALUE] = defaults.value,
  [tuya_types.DatapointSegmentType.STRING] = defaults.string,
  [tuya_types.DatapointSegmentType.ENUM] = defaults.enum,
  [tuya_types.DatapointSegmentType.BITMAP] = defaults.bitmap,
  [tuya_types.DatapointSegmentType.RAW] = defaults.raw,
}

function defaults.command_data_report_handler(datapoints)
  return function (driver, device, zb_rx)
    -- device.parent_assigned_child_key chega sempre nulo
    local dpid = zb_rx.body.zcl_body.data.dpid.value
    local value = zb_rx.body.zcl_body.data.value.value
    local _type = zb_rx.body.zcl_body.data.type.value
    local event = (datapoints[dpid] or map_to_fn[_type] or function () end)(value)

    --log.info("device.preferences.presentation", device.preferences.presentation)
    if event ~= nil then
      -- atualiza o child caso exista 
      local status, e = pcall(device.emit_event_for_endpoint, device, dpid, event)
      -- quando e == nil, significa que encontrou child
      -- como preciso atualizar o parent também, daí tem a lógica abaixo
      if e == nil then
        -- atualiza o parent
        local comp_id = device:get_component_id_for_endpoint(dpid)
        local comp = device.profile.components[comp_id]
        if comp ~= nil then
          device:emit_component_event(comp, event)
        end
      elseif not status then
        log.warn("Unexpected component for datapoint", dpid, value)
        --device:emit_event(event)
      end
      if _type == tuya_types.DatapointSegmentType.BOOLEAN and not myutils.is_normal(device) then
        local switchAll = true
        for dpid,v in pairs(datapoints) do
          if v == defaults.on_off then
            local val,sta = device:get_latest_state(device:get_component_id_for_endpoint(dpid), event.capability.ID, event.attribute.NAME)
            if val ~= event.value.value then
              switchAll = false
              break
            end
          end
        end
        if switchAll then
          if device.profile.components.main == nil then
            log.warn("Profile wasn't applied properly")
          else
            device:emit_component_event(device.profile.components.main, event)
          end
        end
      end
    else
      log.warn("Unexpected datapoint", dpid, value)
    end
  end
end

local function send_command(datapoints, device, command, value)
  --log.info("send_command parent_assigned_child_key", device.parent_assigned_child_key)
  if device.parent_assigned_child_key == nil then
    --log.info("send_command component", command.component, myutils.is_normal(device))
    if command.component ~= "main" or myutils.is_normal(device) then
      device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device, command.component, value))
    else
      for dpid,v in pairs(datapoints) do
        if v == defaults.on_off then
          device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device, string.format("main%02X", dpid), value))
        end
      end
    end
  else
    -- este comando abaixo delega pro get_parent_device()
    device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device:get_parent_device(), "main" .. device.parent_assigned_child_key, value))
  end
end

function defaults.command_on_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, data_types.Boolean(true))
  end
end

function defaults.command_off_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, data_types.Boolean(false))
  end
end

function defaults.command_open_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, data_types.Boolean(true))
  end
end

function defaults.command_close_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, data_types.Boolean(false))
  end
end

function defaults.command_string_handler(datapoints)
  return function (driver, device, command)
    --log.info(utils.stringify_table(command, "command", true))
    --log.info(utils.stringify_table(command.value, "command value", true))
    send_command(datapoints, device, command, data_types.CharString(command.args.value))
  end
end

function defaults.command_raw_handler(datapoints)
  return function (driver, device, command)
    --log.info(utils.stringify_table(command, "command", true))
    --log.info(utils.stringify_table(command.value, "command value", true))
    send_command(datapoints, device, command, generic_body.GenericBody(command.args.value))
  end
end

function defaults.command_enum_handler(datapoints)
  return function (driver, device, command)
    --log.info(utils.stringify_table(command, "command", true))
    --log.info(utils.stringify_table(command.value, "command value", true))
    send_command(datapoints, device, command, data_types.Enum8(command.args.value))
  end
end

function defaults.command_value_handler(datapoints)
  return function (driver, device, command)
    --log.info(utils.stringify_table(command, "command", true))
    --log.info(utils.stringify_table(command.value, "command value", true))
    send_command(datapoints, device, command, tuya_types.Uint32(command.args.value))  -- BigEndian ?
  end
end

function defaults.command_level_handler(datapoints)
  return function (driver, device, command)
    --log.info(utils.stringify_table(command, "command", true))
    --log.info(utils.stringify_table(command.value, "command value", true))
    send_command(datapoints, device, command, tuya_types.Uint32(10 * command.args.level))  -- BigEndian ?
  end
end

function defaults.command_bitmap_handler(datapoints)
  return function (driver, device, command)
    local value = command.args.value
    if value > 0xFFFF then
      send_command(datapoints, device, command, tuya_types.Bitmap32(value)) -- BigEndian ?
    elseif value > 0xFF then
      send_command(datapoints, device, command, tuya_types.Bitmap16(value)) -- BigEndian ?
    else
      send_command(datapoints, device, command, data_types.Bitmap8(value))
    end
  end
end

return defaults