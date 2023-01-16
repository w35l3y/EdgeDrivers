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
  to_zigbee = function (self, value) error("to_zigbee must be implemented") end,
  from_zigbee = function (self, value) return value end,
  command_handler = function (self, command) return self:to_zigbee(command.args.value) end, -- @FIXME
  create_event = function (self, value)
    return self.capability ~= nil and self.attribute ~= nil and capabilities[self.capability][self.attribute](self:from_zigbee(value)) or nil
  end,
}

local defaults = {
  switch = {
    capability = "switch",
    attribute = "switch",
    to_zigbee = function (self, value) return data_types.Boolean(value == "on") end,
    from_zigbee = function (self, value) return to_number(value) == 0 and "off" or "on" end,
    command_handler = function (self, command) return self:to_zigbee(command.command) end,
  },
  switchLevel = {
    capability = "switchLevel",
    attribute = "level",
    rate = 1,
    to_zigbee = function (self, value) return tuya_types.Uint32(math.floor(to_number(value) * self.rate)) end,
    from_zigbee = function (self, value) return math.floor(to_number(value) / self.rate) end,
    command_handler = function (self, command) return self:to_zigbee(command.args.level) end,
  },
  airQualitySensor = {
    capability = "airQualitySensor",
    attribute = "airQuality",
    rate = 1,
    from_zigbee = function (self, value) return math.floor(to_number(value) / self.rate) end,
  },
  button = {
    capability = "button",
    attribute = "button",
    supportedButtonValues = {"pushed", "double", "held"},
    from_zigbee = function (self, value) return self.supportedButtonValues[1 + to_number(value)] or "double" end,
  },
  contactSensor = {
    capability = "contactSensor",
    attribute = "contact",
    from_zigbee = function (self, value) return to_number(value) == 0 and "closed" or "open" end,
  },
  doorControl = {
    capability = "doorControl",
    attribute = "door",
    to_zigbee = function (self, value) return data_types.Boolean(value == "open") end,
    from_zigbee = function (self, value) return to_number(value) == 0 and "closed" or "open" end,
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
    from_zigbee = function (self, value) return to_number(value) == 0 and "inactive" or "active" end,
  },
  occupancySensor = {
    capability = "occupancySensor",
    attribute = "occupancy",
    from_zigbee = function (self, value) return to_number(value) == 0 and "unoccupied" or "occupied" end,
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
  tvocMeasurement = {
    capability = "tvocMeasurement",
    attribute = "tvocLevel",
    rate = 1,
    from_zigbee = function (self, value) return math.floor(to_number(value) / self.rate) end,
  },
  valve = {
    capability = "valve",
    attribute = "valve",
    to_zigbee = function (self, value) return data_types.Boolean(value == "open") end,
    from_zigbee = function (self, value) return to_number(value) == 0 and "closed" or "open" end,
  },
  waterSensor = {
    capability = "waterSensor",
    attribute = "water",
    from_zigbee = function (self, value) return to_number(value) == 0 and "dry" or "wet" end,
  },
  value = {
    capability = "valleyboard16460.datapointValue",
    attribute = "value",
    rate = 1,
    to_zigbee = function (self, value) return tuya_types.Uint32(math.floor(to_number(value) * self.rate)) end,
    from_zigbee = function (self, value) return math.floor(to_number(value) / self.rate) end,
    command_handler = function (self, command) return self:to_zigbee(command.args.value) end,
  },
  string = {
    capability = "valleyboard16460.datapointString",
    attribute = "value",
    to_zigbee = function (self, value) return data_types.CharString(value) end,
    from_zigbee = function (self, value) return tostring(value) end,
    command_handler = function (self, command) return self:to_zigbee(command.args.value) end,
  },
  enum = {
    capability = "valleyboard16460.datapointEnum",
    attribute = "value",
    to_zigbee = function (self, value) return data_types.Enum8(value) end,
    from_zigbee = function (self, value) return to_number(value) end,
    command_handler = function (self, command) return self:to_zigbee(command.args.value) end,
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
    command_handler = function (self, command) return self:to_zigbee(command.args.value) end,
  },
  raw = {
    capability = "valleyboard16460.datapointRaw",
    attribute = "value",
    to_zigbee = function (self, value) return generic_body.GenericBody(value) end,
    from_zigbee = function (self, value) return tostring(value) end,
    command_handler = function (self, command) return self:to_zigbee(command.args.value) end,
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