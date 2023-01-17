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

local default_generic = {
  to_zigbee = function (self, value, device) error("to_zigbee must be implemented") end,
  from_zigbee = function (self, value, device) return value end,
  command_handler = function (self, command, device) return self:to_zigbee(command.args.value, device) end, -- @FIXME
  create_event = function (self, value, device)
    return self.capability ~= nil and self.attribute ~= nil and capabilities[self.capability][self.attribute](self:from_zigbee(value, device)) or nil
  end,
}

local defaults = {
  switch = {
    capability = "switch",
    attribute = "switch",
    to_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      if pref.reverse then
        return data_types.Boolean(value == "off")
      end
      return data_types.Boolean(value == "on")
    end,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
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
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return tuya_types.Uint32(math.floor(to_number(value) * (pref.rate or self.rate)))
    end,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return math.floor(to_number(value) / (pref.rate or self.rate))
    end,
    command_handler = function (self, command, device) return self:to_zigbee(command.args.level, device) end,
  },
  airQualitySensor = {
    capability = "airQualitySensor",
    attribute = "airQuality",
    rate = 1,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return to_number(value) / (pref.rate or self.rate)
    end,
  },
  button = {
    capability = "button",
    attribute = "button",
    supportedButtonValues = {"pushed", "double", "held"},
    from_zigbee = function (self, value) return self.supportedButtonValues[1 + to_number(value)] or "double" end,
  },
  carbonDioxideMeasurement = {
    capability = "carbonDioxideMeasurement",
    attribute = "carbonDioxide",
    rate = 1,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return to_number(value) / (pref.rate or self.rate)
    end,
  },
  contactSensor = {
    capability = "contactSensor",
    attribute = "contact",
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
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
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      if pref.reverse then
        return data_types.Boolean(value == "closed")
      end
      return data_types.Boolean(value == "open")
    end,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      if pref.reverse then
        return to_number(value) == 0 and "open" or "closed"
      end
      return to_number(value) == 0 and "closed" or "open"
    end,
  },
  formaldehydeMeasurement = {
    capability = "formaldehydeMeasurement",
    attribute = "formaldehydeLevel",
    rate = 100,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return to_number(value) / (pref.rate or self.rate)
    end,
  },
  illuminanceMeasurement = {
    capability = "illuminanceMeasurement",
    attribute = "illuminance",
    -- from_zigbee = function (self, value) return math.floor(math.pow(10, (to_number(value) / 10000))) end,
    from_zigbee = function (self, value) return math.floor(1000 * math.log(1 + to_number(value), 0x14)) end,
  },
  motionSensor = {
    capability = "motionSensor",
    attribute = "motion",
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
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
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
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
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
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
    reportingInterval = 2,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return to_number(value) / (pref.rate or self.rate)
    end,
  },
  temperatureMeasurement = {
    capability = "temperatureMeasurement",
    attribute = "temperature",
    rate = 1,
    reportingInterval = 2,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return to_number(value) / (pref.rate or self.rate)
    end,
  },
  tvocMeasurement = {
    capability = "tvocMeasurement",
    attribute = "tvocLevel",
    rate = 100,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return to_number(value) / (pref.rate or self.rate)
    end,
  },
  valve = {
    capability = "valve",
    attribute = "valve",
    to_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      if pref.reverse then
        return data_types.Boolean(value == "closed")
      end
      return data_types.Boolean(value == "open")
    end,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      if pref.reverse then
        return to_number(value) == 0 and "open" or "closed"
      end
      return to_number(value) == 0 and "closed" or "open"
    end,
  },
  waterSensor = {
    capability = "waterSensor",
    attribute = "water",
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
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
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return tuya_types.Uint32(math.floor(to_number(value) * (pref.rate or self.rate)))
    end,
    from_zigbee = function (self, value, device)
      local pref = (device:get_child_by_parent_assigned_key(string.format("%02X", self.group)) or device).preferences
      return to_number(value) / (pref.rate or self.rate)
    end,
    command_handler = function (self, command, device) return self:to_zigbee(command.args.value, device) end,
  },
  string = {
    capability = "valleyboard16460.datapointString",
    attribute = "value",
    to_zigbee = function (self, value) return data_types.CharString(value) end,
    from_zigbee = function (self, value) return tostring(value) end,
    command_handler = function (self, command, device) return self:to_zigbee(command.args.value, device) end,
  },
  enum = {
    capability = "valleyboard16460.datapointEnum",
    attribute = "value",
    to_zigbee = function (self, value) return data_types.Enum8(value) end,
    from_zigbee = function (self, value) return to_number(value) end,
    command_handler = function (self, command, device) return self:to_zigbee(command.args.value, device) end,
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
    command_handler = function (self, command, device) return self:to_zigbee(command.args.value, device) end,
  },
  raw = {
    capability = "valleyboard16460.datapointRaw",
    attribute = "value",
    to_zigbee = function (self, value) return generic_body.GenericBody(value) end,
    from_zigbee = function (self, value) return tostring(value) end,
    command_handler = function (self, command, device) return self:to_zigbee(command.args.value, device) end,
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