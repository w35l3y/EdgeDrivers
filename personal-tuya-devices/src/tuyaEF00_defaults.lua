local log = require "log"
local utils = require "st.utils"

local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"
local generic_body = require "st.zigbee.generic_body"

local myutils = require "utils"

local function to_number (value)
  if type(value) == "boolean" then
    return value and 1 or 0
  elseif type(value) == "string" then
    return tonumber(value, 10) or 0
  elseif type(value) == "nil" then
    return 0
  end
  return value
end

local default_generic = {
  to_zigbee = function (self, value) return value end,
  from_zigbee = function (self, value) return value end,
  create_event = function (self, value)
    return self.capability ~= nil and self.attribute ~= nil and capabilities[self.capability][self.attribute](self:from_zigbee(value)) or nil
  end,
}

local defaults = {
  switch = {
    capability = "switch",
    attribute = "switch",
    from_zigbee = function (self, value) return to_number(value)==0 and "off" or "on" end,
  },
  switchLevel = {
    capability = "switchLevel",
    attribute = "level",
    from_zigbee = function (self, value) return to_number(value) end,
  },
  button = {
    capability = "button",
    attribute = "button",
    domain = {"pushed", "double", "held"},
    from_zigbee = function (self, value) return self.domain[to_number(value)+1] end,
  },
  contactSensor = {
    capability = "contactSensor",
    attribute = "contact",
    from_zigbee = function (self, value) return to_number(value)==0 and "closed" or "open" end,
  },
  doorControl = {
    capability = "doorControl",
    attribute = "door",
    from_zigbee = function (self, value) return to_number(value)==0 and "closed" or "open" end,
  },
  motionSensor = {
    capability = "motionSensor",
    attribute = "motion",
    from_zigbee = function (self, value) return to_number(value)==0 and "inactive" or "active" end,
  },
  presenceSensor = {
    capability = "presenceSensor",
    attribute = "presence",
    from_zigbee = function (self, value) return to_number(value)==0 and "not present" or "present" end,
  },
  temperatureMeasurement = {
    capability = "temperatureMeasurement",
    attribute = "temperature",
    from_zigbee = function (self, value) return to_number(value) end,
  },
  waterSensor = {
    capability = "waterSensor",
    attribute = "water",
    from_zigbee = function (self, value) return to_number(value)==0 and "dry" or "wet" end,
  },
  value = {
    capability = "valleyboard16460.datapointValue",
    attribute = "value",
    from_zigbee = function (self, value) return to_number(value) end,
  },
  string = {
    capability = "valleyboard16460.datapointString",
    attribute = "value",
    from_zigbee = function (self, value) return tostring(value) end,
  },
  enum = {
    capability = "valleyboard16460.datapointEnum",
    attribute = "value",
    from_zigbee = function (self, value) return to_number(value) end,
  },
  bitmap = {
    capability = "valleyboard16460.datapointBitmap",
    attribute = "value",
    from_zigbee = function (self, value) return to_number(value) end,
  },
  raw = {
    capability = "valleyboard16460.datapointRaw",
    attribute = "value",
  },

  dimmer = {
    to_zigbee = function (self, value) return 10 * value end,
    from_zigbee = function (self, value) return math.floor(to_number(value) / 10) end,
  },
}
for k,v in pairs(defaults) do
  setmetatable(v, {__index=default_generic})
end
defaults.generic = default_generic
setmetatable(defaults.dimmer, {__index=defaults.switchLevel})

local map_to_fn = {
  [tuya_types.DatapointSegmentType.BOOLEAN] = defaults.switch,
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
    local event_dp = datapoints[dpid] or map_to_fn[_type] or defaults.generic
    local event = event_dp:create_event(value)

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
      if event_dp == defaults.switch and not myutils.is_normal(device) then
        local switchAll = true
        for dpid, v in pairs(datapoints) do
          if v == defaults.switch then
            local val, sta = device:get_latest_state(device:get_component_id_for_endpoint(dpid), event.capability.ID, event.attribute.NAME)
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

local function send_command(datapoints, device, command, value_fn)
  if device.parent_assigned_child_key == nil then
    if command.component ~= "main" or myutils.is_normal(device) then
      device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device, command.component, value_fn(datapoints[device:get_endpoint_for_component_id(command.component)] or defaults.generic)))
    else
      for dpid, def in pairs(datapoints) do
        if def == defaults.switch then
          device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device, string.format("main%02X", dpid), value_fn(def)))
        end
      end
    end
  else
    -- este comando abaixo delega pro get_parent_device()
    device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device:get_parent_device(), "main" .. device.parent_assigned_child_key, value_fn(datapoints[tonumber(device.parent_assigned_child_key, 16)] or defaults.generic)))
  end
end

function defaults.command_true_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, function () return data_types.Boolean(true) end)
  end
end

function defaults.command_false_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, function () return data_types.Boolean(false) end)
  end
end

function defaults.command_switchLevel_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, function (e) return tuya_types.Uint32(e:to_zigbee(command.args.level)) end)  -- BigEndian ?
  end
end

function defaults.command_value_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, function () return tuya_types.Uint32(command.args.value) end)  -- BigEndian ?
  end
end

function defaults.command_string_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, function () return data_types.CharString(command.args.value) end)
  end
end

function defaults.command_enum_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, function() return data_types.Enum8(command.args.value) end)
  end
end

function defaults.command_bitmap_handler(datapoints)
  return function (driver, device, command)
    local value = command.args.value
    if value > 0xFFFF then
      send_command(datapoints, device, command, function () return tuya_types.Bitmap32(value) end) -- BigEndian ? untested
    elseif value > 0xFF then
      send_command(datapoints, device, command, function () return tuya_types.Bitmap16(value) end) -- BigEndian ? untested
    else
      send_command(datapoints, device, command, function () return data_types.Bitmap8(value) end)
    end
  end
end

function defaults.command_raw_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command, function () return generic_body.GenericBody(command.args.value) end)
  end
end

return defaults