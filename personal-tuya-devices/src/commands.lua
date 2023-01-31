local log = require "log"
local utils = require "st.utils"

local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"
local generic_body = require "st.zigbee.generic_body"

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

-- tries to make it partially work with firmware below 45.1
local function get_child_or_parent(device, group)
  if (device.get_child_by_parent_assigned_key == nil) then
    log.warn("Driver requires firmware 45.1+ to work properly")
    return device
  end
  return device:get_child_by_parent_assigned_key(string.format("%02X", group)) or device
end

local default_generic = {
  attribute = "value",
  to_zigbee = function (self, value, device) error("to_zigbee must be implemented") end,
  from_zigbee = function (self, value, device) return value end,
  command_handler = function (self, command, device) return self:to_zigbee(command.args[self.attribute], device) end,
  create_event = function (self, value, device)
    return self.capability ~= nil and self.attribute ~= nil and capabilities[self.capability][self.attribute](self:from_zigbee(value, device)) or nil
  end,
}

local function get_value(name, pref, cmd)
  if pref[name] ~= nil and pref[name] ~= 0 then
    return pref[name]
  end
  return cmd[name]
end

local defaults = {
  switch = {
    capability = "switch",
    attribute = "switch",
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return data_types.Boolean(value == "off")
      end
      return data_types.Boolean(value == "on")
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return to_number(value) == 0 and "on" or "off"
      end
      return to_number(value) == 0 and "off" or "on"
    end,
    command_handler = function (self, command, device) return self:to_zigbee(command.command, device) end,
  },
  switchLevel = {
    capability = "switchLevel",
    attribute = "level",
    rate = 1,
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return tuya_types.Uint32(math.floor(to_number(value) * get_value("rate", pref, self)))
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(to_number(value) / get_value("rate", pref, self))
    end,
  },
  airQualitySensor = {
    capability = "airQualitySensor",
    attribute = "airQuality",
    rate = 1,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return to_number(value) / get_value("rate", pref, self)
    end,
  },
  button = {
    capability = "button",
    attribute = "button",
    supportedButtonValues = { "pushed", "double", "held" },
    from_zigbee = function (self, value) return self.supportedButtonValues[1 + to_number(value)] or "double" end,
  },
  carbonDioxideMeasurement = {
    capability = "carbonDioxideMeasurement",
    attribute = "carbonDioxide",
    rate = 1,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return to_number(value) / get_value("rate", pref, self)
    end,
  },
  contactSensor = {
    capability = "contactSensor",
    attribute = "contact",
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return to_number(value) == 0 and "open" or "closed"
      end
      return to_number(value) == 0 and "closed" or "open"
    end,
  },
  doorControl = {
    capability = "doorControl",
    attribute = "door",
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return data_types.Boolean(value == "closed")
      end
      return data_types.Boolean(value == "open")
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return to_number(value) == 0 and "open" or "closed"
      end
      return to_number(value) == 0 and "closed" or "open"
    end,
    command_handler = function (self, command, device) return self:to_zigbee(command.command == "open" and "open" or "closed", device) end,
  },
  dustSensor = {
    capability = "dustSensor",
    attribute = "dustLevel",
    rate = 1,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return to_number(value) / get_value("rate", pref, self)
    end,
  },
  fineDustSensor = {
    capability = "fineDustSensor",
    attribute = "fineDustLevel",
    rate = 1,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return to_number(value) / get_value("rate", pref, self)
    end,
  },
  veryFineDustSensor = {
    capability = "veryFineDustSensor",
    attribute = "veryFineDustLevel",
    rate = 1,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return to_number(value) / get_value("rate", pref, self)
    end,
  },
  formaldehydeMeasurement = {
    capability = "formaldehydeMeasurement",
    attribute = "formaldehydeLevel",
    rate = 100,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return to_number(value) / get_value("rate", pref, self)
    end,
  },
  illuminanceMeasurement = {
    capability = "illuminanceMeasurement",
    attribute = "illuminance",
    reportingInterval = 0.2,
    -- from_zigbee = function (self, value) return math.floor(math.pow(10, (to_number(value) / 10000))) end,
    from_zigbee = function (self, value) return math.floor(1000 * math.log(1 + to_number(value), 0x14)) end,
  },
  motionSensor = {
    capability = "motionSensor",
    attribute = "motion",
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return to_number(value) == 0 and "active" or "inactive"
      end
      return to_number(value) == 0 and "inactive" or "active"
    end,
  },
  occupancySensor = {
    capability = "occupancySensor",
    attribute = "occupancy",
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return to_number(value) == 0 and "occupied" or "unoccupied"
      end
      return to_number(value) == 0 and "unoccupied" or "occupied"
    end,
  },
  presenceSensor = {
    capability = "presenceSensor",
    attribute = "presence",
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return to_number(value) == 0 and "present" or "not present"
      end
      return to_number(value) == 0 and "not present" or "present"
    end,
  },
  relativeHumidityMeasurement = {
    capability = "relativeHumidityMeasurement",
    attribute = "humidity",
    rate = 1,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return to_number(value) / get_value("rate", pref, self)
    end,
  },
  temperatureMeasurement = {
    capability = "temperatureMeasurement",
    attribute = "temperature",
    rate = 1,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return to_number(value) / get_value("rate", pref, self)
    end,
  },
  tvocMeasurement = {
    capability = "tvocMeasurement",
    attribute = "tvocLevel",
    rate = 100,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return to_number(value) / get_value("rate", pref, self)
    end,
  },
  valve = {
    capability = "valve",
    attribute = "valve",
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return data_types.Boolean(value == "closed")
      end
      return data_types.Boolean(value == "open")
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return to_number(value) == 0 and "open" or "closed"
      end
      return to_number(value) == 0 and "closed" or "open"
    end,
    command_handler = function (self, command, device) return self:to_zigbee(command.command == "open" and "open" or "closed", device) end,
  },
  waterSensor = {
    capability = "waterSensor",
    attribute = "water",
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return to_number(value) == 0 and "wet" or "dry"
      end
      return to_number(value) == 0 and "dry" or "wet"
    end,
  },
  value = {
    capability = "valleyboard16460.datapointValue",
    attribute = "value",
    rate = 1,
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return tuya_types.Uint32(math.floor(to_number(value) * get_value("rate", pref, self)))
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(to_number(value) / get_value("rate", pref, self))
    end,
  },
  string = {
    capability = "valleyboard16460.datapointString",
    attribute = "value",
    to_zigbee = function (self, value) return data_types.CharString(value) end,
    from_zigbee = function (self, value) return tostring(value) end,
  },
  enum = {
    capability = "valleyboard16460.datapointEnum",
    attribute = "value",
    to_zigbee = function (self, value) return data_types.Enum8(value) end,
    from_zigbee = function (self, value) return to_number(value) end,
  },
  bitmap = {
    capability = "valleyboard16460.datapointBitmap",
    attribute = "value",
    to_zigbee = function (self, value)
      local v = to_number(value)
      if v > 0xFFFF then
        return tuya_types.Bitmap32(v) -- BigEndian ? untested
      elseif v > 0xFF then
        return tuya_types.Bitmap16(v) -- BigEndian ? untested
      end
      return data_types.Bitmap8(v)
    end,
    from_zigbee = function (self, value) return to_number(value) end,
  },
  raw = {
    capability = "valleyboard16460.datapointRaw",
    attribute = "value",
    to_zigbee = function (self, value) return generic_body.GenericBody(value) end,
    from_zigbee = function (self, value) return tostring(value) end,
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

return defaults
