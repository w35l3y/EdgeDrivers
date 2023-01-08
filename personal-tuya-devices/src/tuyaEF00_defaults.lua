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
    to_zigbee = function (self, value) return value == "on" end,
    from_zigbee = function (self, value) return to_number(value) == 0 and "off" or "on" end,
    command_handler = function (self, evt) return data_types.Boolean(self:to_zigbee(evt.command)) end,
  },
  switchLevel = {
    capability = "switchLevel",
    attribute = "level",
    divider = 1,
    to_zigbee = function (self, value) return to_number(value) * self.divider end,
    from_zigbee = function (self, value) return math.floor(to_number(value) / self.divider) end,
    command_handler = function (self, command) return tuya_types.Uint32(self:to_zigbee(command.args.level)) end,
  },
  button = {
    capability = "button",
    attribute = "button",
    domain = {"pushed", "double", "held"},
    from_zigbee = function (self, value) return self.domain[1 + to_number(value)] or "double" end,
  },
  contactSensor = {
    capability = "contactSensor",
    attribute = "contact",
    from_zigbee = function (self, value) return to_number(value) == 0 and "closed" or "open" end,
  },
  doorControl = {
    capability = "doorControl",
    attribute = "door",
    to_zigbee = function (self, value) return to_number(value == "open") end,
    from_zigbee = function (self, value) return to_number(value) == 0 and "closed" or "open" end,
  },
  illuminanceMeasurement = {
    capability = "illuminanceMeasurement",
    attribute = "illuminance",
    from_zigbee = function (self, value) return math.floor(1000 * math.log(1 + to_number(value), 0x14)) end,
  },
  motionSensor = {
    capability = "motionSensor",
    attribute = "motion",
    from_zigbee = function (self, value) return to_number(value) == 0 and "inactive" or "active" end,
  },
  presenceSensor = {
    capability = "presenceSensor",
    attribute = "presence",
    from_zigbee = function (self, value) return to_number(value) == 0 and "not present" or "present" end,
  },
  relativeHumidityMeasurement = {
    capability = "relativeHumidityMeasurement",
    attribute = "humidity",
    from_zigbee = function (self, value) return to_number(value) end,
  },
  temperatureMeasurement = {
    capability = "temperatureMeasurement",
    attribute = "temperature",
    from_zigbee = function (self, value) return to_number(value) end,
  },
  waterSensor = {
    capability = "waterSensor",
    attribute = "water",
    from_zigbee = function (self, value) return to_number(value) == 0 and "dry" or "wet" end,
  },
  value = {
    capability = "valleyboard16460.datapointValue",
    attribute = "value",
    from_zigbee = function (self, value) return to_number(value) end,
    command_handler = function (self, command) return tuya_types.Uint32(command.args.value) end,
  },
  string = {
    capability = "valleyboard16460.datapointString",
    attribute = "value",
    from_zigbee = function (self, value) return tostring(value) end,
    command_handler = function (self, command) return data_types.CharString(command.args.value) end,
  },
  enum = {
    capability = "valleyboard16460.datapointEnum",
    attribute = "value",
    from_zigbee = function (self, value) return to_number(value) end,
    command_handler = function(self, command) return data_types.Enum8(command.args.value) end,
  },
  bitmap = {
    capability = "valleyboard16460.datapointBitmap",
    attribute = "value",
    from_zigbee = function (self, value) return to_number(value) end,
    command_handler = function (self, command)
      local value = command.args.value
      if value > 0xFFFF then
        return tuya_types.Bitmap32(value) -- BigEndian ? untested
      elseif value > 0xFF then
        return tuya_types.Bitmap16(value) -- BigEndian ? untested
      end
      return data_types.Bitmap8(value)
    end
  },
  raw = {
    capability = "valleyboard16460.datapointRaw",
    attribute = "value",
    from_zigbee = function (self, value) return tostring(value) end,
    command_handler = function (self, command) return generic_body.GenericBody(command.args.value) end,
  },
}

for k,v in pairs(defaults) do
  setmetatable(v, {
    __index=v.parent and defaults[v.parent] or default_generic,
    __call=function (self, base)
      setmetatable(base, {
        __index=self
      })
      return base
    end
  })
end
defaults.generic = default_generic

local map_to_fn = {
  [tuya_types.DatapointSegmentType.BOOLEAN] = defaults.switch,
  [tuya_types.DatapointSegmentType.VALUE] = defaults.value,
  [tuya_types.DatapointSegmentType.STRING] = defaults.string,
  [tuya_types.DatapointSegmentType.ENUM] = defaults.enum,
  [tuya_types.DatapointSegmentType.BITMAP] = defaults.bitmap,
  [tuya_types.DatapointSegmentType.RAW] = defaults.raw,
}

function defaults.command_response_handler(datapoints)
  return function (driver, device, zb_rx)
    -- device.parent_assigned_child_key chega sempre nulo
    local dpid = zb_rx.body.zcl_body.data.dpid.value
    local value = zb_rx.body.zcl_body.data.value.value
    local _type = zb_rx.body.zcl_body.data.type.value
    local event_dp = datapoints[dpid] or map_to_fn[_type]({group=dpid}) or defaults.generic
    local event = event_dp:create_event(value)

    --log.info("device.preferences.presentation", device.preferences.presentation)
    if event ~= nil then
      -- atualiza o child caso exista 
      local status, e = pcall(device.emit_event_for_endpoint, device, event_dp.group or dpid, event)
      -- quando e == nil, significa que encontrou child
      -- como preciso atualizar o parent também, daí tem a lógica abaixo
      if e == nil then
        -- atualiza o parent
        local comp_id = device:get_component_id_for_endpoint(event_dp.group or dpid)
        local comp = device.profile.components[comp_id]
        if comp ~= nil then
          device:emit_component_event(comp, event)
        end
      elseif not status then
        log.warn("Unexpected component for datapoint", event_dp.group, dpid, value)
        --device:emit_event(event)
      end
      if device.profile.components.main == nil then
        log.warn("Profile wasn't applied properly")
      elseif not myutils.is_normal(device) then
        local updateAll = 0
        for cdpid, v in pairs(datapoints) do
          if v.capability == event.capability.ID and v.attribute == event.attribute.NAME then
            local val, sta = device:get_latest_state(device:get_component_id_for_endpoint(v.group or cdpid), event.capability.ID, event.attribute.NAME)
            if val ~= event.value.value then
              updateAll = 0
              break
            else
              updateAll = 1 + updateAll
            end
          end
        end
        if updateAll > 0 then
          device:emit_component_event(device.profile.components.main, event)
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
      local group = device:get_endpoint_for_component_id(command.component)
      for dpid, def in pairs(datapoints) do
        if group == def.group and command.capability == def.capability then
          device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device, dpid, def:command_handler(command)))
          break
        end
      end
    else
      for dpid, def in pairs(datapoints) do
        if command.capability == def.capability then
          device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device, dpid, def:command_handler(command)))
        end
      end
    end
  else
    local group = tonumber(device.parent_assigned_child_key, 16)
    for dpid, def in pairs(datapoints) do
      if group == def.group and command.capability == def.capability then
        -- este comando abaixo delega pro get_parent_device()
        device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device:get_parent_device(), dpid, def:command_handler(command)))
      end
    end
  end
end

function defaults.capability_handler(datapoints)
  return function (driver, device, command)
    send_command(datapoints, device, command)
  end
end

return defaults