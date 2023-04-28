local log = require "log"
local utils = require "st.utils"

local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"
local generic_body = require "st.zigbee.generic_body"

-- local json = require('dkjson')

local function to_number (value)
  if type(value) == "boolean" then
    return value and 1 or 0
  elseif type(value) == "string" then
    return tonumber(value, 10) or 0
  elseif type(value) == "nil" then
    log.warn("value is nil. converted to 0")
    return 0
  end
  return value
end

local function to_bool (value)
  return value ~= nil and value ~= false
end

local function xor (a, b)
  return to_bool(a) ~= to_bool(b)
end

-- tries to make it partially work with firmware below 45.1
local function get_child_or_parent(device, group, force_child)
  if (device.get_child_by_parent_assigned_key == nil) then
    log.warn("Driver requires firmware 45.1+ to work properly")
    return device
  end
  local child = device:get_child_by_parent_assigned_key(string.format("%02X", group))
  -- if not child or group == 1 and not force_child then
  --   return device
  -- end
  -- return child or device

  return (not child or (group == 1 and not force_child)) and device or child
end

local map_cap_to_pref = {
  ["valleyboard16460.datapointValue"] = "value",
  ["valleyboard16460.datapointString"] = "string",
  ["valleyboard16460.datapointEnum"] = "enum",
  ["valleyboard16460.datapointBitmap"] = "bitmap",
  ["valleyboard16460.datapointRaw"] = "raw",
}

local default_generic = {
  additional = {},
  attribute = "value",
  get_dp = function (def, dp, device)
    local cap = string.sub(utils.pascal_case(utils.snake_case(map_cap_to_pref[def.capability] or def.capability)), 1, 16)
    local pref_name = "dp" .. cap .. "Main" .. string.format("%02X", def.group)
    if device.parent_assigned_child_key then
      local pdp = device:get_parent_device().preferences[pref_name]
      if type(pdp) == "userdata" then
        log.warn("1 Unexpected config type", pref_name, pdp, cap)
        pdp = 0
      end
      -- log.info("PREFNAME 1", pref_name, pdp, dp, pdp == nil, type(pdp), cap)
      return (not dp or pdp ~= 0) and pdp or dp
    end
    local pdp = device.preferences[pref_name]
    if type(pdp) == "userdata" then
      log.warn("2 Unexpected config type", pref_name, pdp, cap)
      pdp = 0
    end
    -- log.info("PREFNAME 2", pref_name, pdp, dp, pdp == nil, type(pdp), cap)
    return (not dp or pdp ~= 0) and pdp or dp
  end,
  to_zigbee = function (self, value, device) error("to_zigbee must be implemented", self.capability, self.attribute) end,
  from_zigbee = function (self, value, device, force_child, datapoints) return value end,
  command_handler = function (self, dpid, command, device) return { math.abs(self:get_dp(dpid, device)), self:to_zigbee(self:command_to_value(command, device), device) } end,
  command_to_value = function (self, command, device) return command.args[self.command_arg or self.attribute] end,
  create_event = function (self, value, device, force_child, datapoints)
    return self.capability and self.attribute and capabilities[self.capability][self.attribute](self:from_zigbee(value, device, force_child, datapoints)) or nil
  end,
}

local function get_pref (value, default, name)
  if type(value) == "userdata" then
    log.warn("Unexpected type for preference", name, value, default)
    return default
  end
  return value or default
end

local function get_value (pref, cmd)
  if pref and pref ~= 0 then
    return to_number(pref)
  end
  return cmd
end

local function unescape (str)
  local output = string.gsub(str, "\\x(%x+)", function (o) return string.char(tonumber(o, 16)) end)
  return output
end

local function get_temp_unit(value)
  return type(value) ~= "userdata" and value or "C"
end

local function get_app_temp_unit (pref)
  return get_temp_unit(pref.temperatureUnit)
end

local function get_dev_temp_unit(device)
  return get_temp_unit(device:get_field("prefTemperatureUnit"))
end

local function get_temp (value, from_unit, to_unit)
  return {
    value = from_unit == to_unit and value or (to_unit == "F" and utils.c_to_f(value) or utils.f_to_c(value)),
    unit = to_unit
  }
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
      local v = to_number(value)
      if pref.reverse then
        return v == 0 and "on" or "off"
      end
      return v == 0 and "off" or "on"
    end,
    command_to_value = function (self, command) return command.command end,
  },
  switchLevel = {
    capability = "switchLevel",
    attribute = "level",
    rate_name = "rate",
    rate = 100,
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return tuya_types.Uint32(math.floor(to_number(value) * get_value(pref[self.rate_name], self.rate) / 100))
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate))
    end,
  },
  airQualitySensor = {
    capability = "airQualitySensor",
    attribute = "airQuality",
    rate_name = "rate",
    rate = 100,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return 100 * to_number(value) / get_value(pref[self.rate_name], self.rate)
    end,
  },
  alarm = {
    capability = "alarm",
    attribute = "alarm",
    to_zigbee = function (self, value, device)
      return data_types.Boolean(value ~= "off")
    end,
    from_zigbee = function (self, value, device)
      local v = to_number(value)
      return v == 0 and "off" or "both"
    end,
    command_to_value = function (self, command) return command.command end,
  },
  audioMute = {
    capability = "audioMute",
    attribute = "mute",
    command_arg = "state",
    to_zigbee = function (self, value, device)
      return data_types.Boolean(value ~= "unmuted")
    end,
    from_zigbee = function (self, value, device)
      local v = to_number(value)
      return v == 0 and "unmuted" or "muted"
    end,
    command_to_value = function (self, command) return command.command == "mute" and "muted" or "unmuted" end,
  },
  audioVolume = {
    capability = "audioVolume",
    attribute = "volume",
    supported_values = {},
    -- supported_values = {0,34,67,100}, -- off,low,medium,high
    -- supported_values = {0,50,100}, -- low,medium,high
    to_zigbee = function (self, value, device)
      if #self.supported_values > 1 then
        local m = 100 / (#self.supported_values - 1) -- 50          33.333333
        local x = 100 / #self.supported_values       -- 33.333333   25
        return data_types.Enum8(math.min(100, math.floor(m * math.floor(to_number(value) / x) + 0.5)))
      end
      return tuya_types.Uint32(to_number(value))
    end,
    from_zigbee = function (self, value, device)
      local v = to_number(value)
      if #self.supported_values > 1 then
        return self.supported_values[1 + v]
      end
      return v
    end,
    command_to_value = function (self, command, device) return command.args[self.attribute] or device:get_latest_state(command.component, self.capability, self.attribute, 0, 0)+(command.command == "volumeUp" and 1 or -1) end,
  },
  battery = {
    capability = "battery",
    attribute = "battery",
    rate_name = "rate",
    rate = 100,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate))
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
    rate_name = "rate",
    rate = 100,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return 100 * to_number(value) / get_value(pref[self.rate_name], self.rate)
    end,
  },
  -- colorControl = {
  --   capability = "colorControl",
  --   attribute = "color",
  --   to_zigbee = function (self, value, device)
  --     -- log.info("to_zigbee", utils.stringify_table(value, "color", true))
  --     -- https://developer.tuya.com/en/docs/iot/tuya-zigbee-lighting-access-standard?id=K9ik6zvod83fi#title-12-DP5%20Color
  --     -- local red, green, blue = utils.hsl_to_rgb(value.color.hue, value.color.saturation)
  --     -- local color = (red << 16) + (green << 8) + blue
  --     local hue, sat, val = math.floor(value.hue * 0x0168) << 32, math.floor(value.saturation * 0x03E8) << 16, math.floor(0 * 0x0358)
  --     -- log.info("to_zigbee", hue, sat, val)
  --     -- @FIXME it won't work properly as `Uint48` isn't known tuya data type
  --     return data_types.Uint48(hue + sat + val)
  --     -- return generic_body.GenericBody(hue+sat+val)
  --   end,
  --   from_zigbee = function (self, value, device)
  --     local color = to_number(value)
  --     -- log.info("from_zigbee", value, color, string.format("%X", color))
  --     -- local red, green, blue = (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF
  --     -- local hue, sat, lightness = utils.rgb_to_hsl(red, green, blue)
  --     -- @FIXME it won't work as `Uint48` isn't known tuya data type
  --     local hue, sat, val = ((color >> 32) & 0xFFFF) / 0x0168, ((color >> 16) & 0xFFFF) / 0x03E8, (color & 0xFFFF) / 0x03E8
  --     -- log.info("from_zigbee", hue, sat, val)
  --     return json.encode({
  --       color = {
  --         hue = hue,
  --         saturation = sat,
  --         -- lightness = lightness
  --       }
  --     })
  --   end,
  -- },
  -- colorTemperature = {
  --   capability = "colorTemperature",
  --   attribute = "colorTemperature",
  --   rate_name = "rate",
  --   rate = 100,
  --   to_zigbee = function (self, value, device)
  --     local pref = get_child_or_parent(device, self.group).preferences
  --     return tuya_types.Uint16(math.floor(to_number(value) * get_value(pref[self.rate_name], self.rate) / 100))
  --   end,
  --   from_zigbee = function (self, value, device)
  --     local pref = get_child_or_parent(device, self.group).preferences
  --     return math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate))
  --   end,
  -- },
  contactSensor = {
    capability = "contactSensor",
    attribute = "contact",
    reverse = false,
    from_zigbee = function (self, value, device, force_child)
      local pref = get_child_or_parent(device, self.group, force_child).preferences
      -- log.info(self.capability, pref.reverse)
      local v = to_number(value)
      if xor(self.reverse, pref.reverse) then
        return v == 0 and "open" or "closed"
      end
      return v == 0 and "closed" or "open"
    end,
  },
  currentMeasurement = {
    capability = "currentMeasurement",
    attribute = "current",
    rate_name = "rate",
    rate = 10000,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return 10 * to_number(value) / get_value(pref[self.rate_name], self.rate)
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
      local v = to_number(value)
      if pref.reverse then
        return v == 0 and "open" or "closed"
      end
      return v == 0 and "closed" or "open"
    end,
    command_to_value = function (self, command) return command.command == "open" and "open" or "closed" end,
  },
  dustSensor = {
    capability = "dustSensor",
    attribute = "dustLevel",
    rate_name = "rate",
    rate = 100,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate))
    end,
  },
  energyMeter = {
    capability = "energyMeter",
    attribute = "energy",
    rate_name = "rate",
    rate = 10000,
    to_zigbee = function (self, value, device)  -- resetEnergyMeter (untested!)
      local pref = get_child_or_parent(device, self.group).preferences
      return tuya_types.Uint32(0)
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return 10 * to_number(value) / get_value(pref[self.rate_name], self.rate)
    end,
    command_to_value = function (self, command) return command.command end,
  },
  fineDustSensor = {
    capability = "fineDustSensor",
    attribute = "fineDustLevel",
    rate_name = "rate",
    rate = 100,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate))
    end,
  },
  gasDetector = {
    capability = "gasDetector",
    attribute = "gas",
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      local v = to_number(value)
      local output = nil
      if pref.reverse then
        output = v == 0 and "clear" or (device:get_field("tested") and "tested" or "detected")
      else
        output = v == 0 and (device:get_field("tested") and "tested" or "detected") or "clear"
      end
      if output == "clear" then
        device:set_field("tested", nil)
      end
      return output
    end,
  },
  testCapability = {
    create_event = function (self, value, device, force_child)  -- from_zigbee
      return self.capability and self.attribute and capabilities[self.capability][self.attribute](to_number(value) == 1 and self.on or self.off) or nil
    end,
  },
  momentaryAudioMuteTestCapability = {
    capability = "momentary",
    create_event = function (self, value, device, force_child, datapoints)  -- from_zigbee
      return nil
    end,
    command_handler = function (self, dpid, command, device, datapoints)  -- to_zigbee
      local cmd = datapoints[self.testCapability]
      local state = device:get_latest_state(command.component, cmd.capability, cmd.attribute, "clear", "clear")
      if state == "detected" then
        return { math.abs(self:get_dp(dpid, device)), data_types.Boolean(true) }  -- mute
      else
        device:set_field("tested", state ~= "tested")
        return { math.abs(self:get_dp(self.testCapability, device)), data_types.Boolean(state ~= "tested") }  -- tested
      end
    end,
    -- Device:get_latest_state(component_id, capability_id, attribute_name, default_value, default_state_table)
    -- command_to_value = function (self, command, device) return command.args[self.attribute] or device:get_latest_state(command.component, self.capability, self.attribute, 0, 0)+(command.command == "volumeUp" and 1 or -1) end,
  },
  formaldehydeMeasurement = {
    capability = "formaldehydeMeasurement",
    attribute = "formaldehydeLevel",
    rate_name = "rate",
    rate = 10000,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return {
        value = 100 * to_number(value) / get_value(pref[self.rate_name], self.rate),
        unit = "ppm"
      }
    end,
  },
  illuminanceMeasurement = {
    capability = "illuminanceMeasurement",
    attribute = "illuminance",
    rate_name = "rate",
    rate = 100,
    reportingInterval = 0.2,
    -- from_zigbee = function (self, value) return math.floor(math.pow(10, (to_number(value) / 10000))) end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      local v = 100 * to_number(value) / get_value(pref[self.rate_name], self.rate)
      return math.floor(1000 * math.log(1 + v, 0x14))
    end,
  },
  illuminanceMeasurementRaw = {
    capability = "illuminanceMeasurement",
    attribute = "illuminance",
    rate_name = "rate",
    rate = 100,
    reportingInterval = 0.2,
    -- from_zigbee = function (self, value) return math.floor(math.pow(10, (to_number(value) / 10000))) end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate))
    end,
  },
  keypadInput = {
    capability = "keypadInput",
    attribute = "keyCode",
    -- supported_values = {},
    -- supported_values = {"NUMBER0","NUMBER1","NUMBER2","NUMBER3","NUMBER4","NUMBER5","NUMBER6","NUMBER7","NUMBER8","NUMBER9","UP","RIGHT","DOWN","LEFT","SELECT","EXIT","MENU","BACK","SETTINGS","HOME"},
    supported_values = {"UP","DOWN","LEFT","RIGHT","SELECT","BACK","EXIT","MENU","SETTINGS","HOME","NUMBER0","NUMBER1","NUMBER2","NUMBER3","NUMBER4","NUMBER5","NUMBER6","NUMBER7","NUMBER8","NUMBER9"},
    to_zigbee = function (self, value, device)
      -- log.info("keypadInput", value)
      if #self.supported_values == 0 then
        return tuya_types.Uint32(string.byte(value))
      end
      for i, v in ipairs(self.supported_values) do
        if v == value then
          return data_types.Enum8(i - 1)
        end
      end
      log.warn("keypadInput : unsupported value", value)
      return data_types.Enum8(string.byte(value))
    end,
  },
  motionSensor = {
    capability = "motionSensor",
    attribute = "motion",
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      local v = to_number(value)
      if pref.reverse then
        return v == 0 and "active" or "inactive"
      end
      return v == 0 and "inactive" or "active"
    end,
  },
  occupancySensor = {
    capability = "occupancySensor",
    attribute = "occupancy",
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      local v = to_number(value)
      if pref.reverse then
        return v == 0 and "occupied" or "unoccupied"
      end
      return v == 0 and "unoccupied" or "occupied"
    end,
  },
  powerMeter = {
    capability = "powerMeter",
    attribute = "power",
    rate_name = "rate",
    rate = 1000,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return 100 * to_number(value) / get_value(pref[self.rate_name], self.rate)
    end,
  },
  presenceSensor = {
    capability = "presenceSensor",
    attribute = "presence",
    reverse = false,
    from_zigbee = function (self, value, device, force_child)
      local pref = get_child_or_parent(device, self.group, force_child).preferences
      -- log.info(self.capability, pref.reverse)
      local v = to_number(value)
      if xor(self.reverse, pref.reverse) then
        return v == 0 and "present" or "not present"
      end
      return v == 0 and "not present" or "present"
    end,
    additional = {
      {
        command = "contactSensor",
      }
    },
  },
  relativeHumidityMeasurement = {
    capability = "relativeHumidityMeasurement",
    attribute = "humidity",
    rate_name = "rate",
    rate = 100,
    humidityOffset_name = "humidityOffset",
    humidityOffset = 0.0,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return (100 * to_number(value) / get_value(pref[self.rate_name], self.rate)) + get_value(pref[self.humidityOffset_name], self.humidityOffset)
    end,
  },
  temperatureMeasurement = {
    capability = "temperatureMeasurement",
    attribute = "temperature",
    rate_name = "rate",
    rate = 100,
    tempOffset_name = "tempOffset",
    tempOffset = 0.0,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return get_temp((100 * to_number(value) / get_value(pref[self.rate_name], self.rate)) + get_value(pref[self.tempOffset_name], self.tempOffset), get_dev_temp_unit(device), get_app_temp_unit(pref))
    end,
  },
  thermostatCoolingSetpoint = {
    capability = "thermostatCoolingSetpoint",
    attribute = "coolingSetpoint",
    command_arg = "setpoint",
    rate_name = "rate",
    rate = 100,
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return tuya_types.Uint32(math.floor(get_temp(to_number(value), get_app_temp_unit(pref), get_dev_temp_unit(device)).value * get_value(pref[self.rate_name], self.rate) / 100))
      -- return tuya_types.Uint32(math.floor(to_number(value) * get_value(pref[self.rate_name], self.rate) / 100))
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return get_temp(math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate)), get_dev_temp_unit(device), get_app_temp_unit(pref))
    end,
  },
  thermostatHeatingSetpoint = {
    capability = "thermostatHeatingSetpoint",
    attribute = "heatingSetpoint",
    command_arg = "setpoint",
    rate_name = "rate",
    rate = 100,
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return tuya_types.Uint32(math.floor(get_temp(to_number(value), get_app_temp_unit(pref), get_dev_temp_unit(device)).value * get_value(pref[self.rate_name], self.rate) / 100))
      -- return tuya_types.Uint32(math.floor(to_number(value) * get_value(pref[self.rate_name], self.rate) / 100))
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return get_temp(math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate)), get_dev_temp_unit(device), get_app_temp_unit(pref))
    end,
  },
  thermostatMode = {
    capability = "thermostatMode",
    attribute = "thermostatMode",
    command_arg = "mode",
    supported_values = { "manual", "heat", "away", "auto", "eco" },
    to_zigbee = function (self, value, device)
      for i, v in ipairs(self.supported_values) do
        if v == value then
          return data_types.Enum8(i - 1)
        end
      end
      log.warn("thermostatMode : unsupported value", value)
      return data_types.Enum8(0)
    end,
    from_zigbee = function (self, value, device)
      local v = to_number(value)
      return self.supported_values[1 + v] or "custom"
    end
  },
  thermostatOperatingState = {
    capability = "thermostatOperatingState",
    attribute = "thermostatOperatingState",
    from_zigbee = function (self, value, device)
      local v = to_number(value)
      return v == 0 and "idle" or "heating"
    end
  },
  tvocMeasurement = {
    capability = "tvocMeasurement",
    attribute = "tvocLevel",
    rate_name = "rate",
    rate = 10000,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return {
        value = 100 * to_number(value) / get_value(pref[self.rate_name], self.rate),
        unit = "ppm"
      }
    end,
  },
  valve = {
    capability = "valve",
    attribute = "valve",
    type_name = "valveType",
    type = "bool",
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if get_pref(pref[self.type_name], self.type, self.type_name) == "enum" then
        if pref.reverse then
          return data_types.Enum8(value == "closed" and 1 or 0)
        end
        return data_types.Enum8(value == "open" and 1 or 0)
      end
      if pref.reverse then
        return data_types.Boolean(value == "closed")
      end
      return data_types.Boolean(value == "open")
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      local v = to_number(value)
      if pref.reverse then
        return v == 0 and "open" or "closed"
      end
      return v == 0 and "closed" or "open"
    end,
    command_to_value = function (self, command) return command.command == "open" and "open" or "closed" end,
  },
  veryFineDustSensor = {
    capability = "veryFineDustSensor",
    attribute = "veryFineDustLevel",
    rate_name = "rate",
    rate = 100,
    reportingInterval = 1,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate))
    end,
  },
  voltageMeasurement = {
    capability = "voltageMeasurement",
    attribute = "voltage",
    rate_name = "rate",
    rate = 1000,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return 100 * to_number(value) / get_value(pref[self.rate_name], self.rate)
    end,
  },
  waterSensor = {
    capability = "waterSensor",
    attribute = "water",
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      local v = to_number(value)
      if pref.reverse then
        return v == 0 and "wet" or "dry"
      end
      return v == 0 and "dry" or "wet"
    end,
  },
  windowShade = {
    capability = "windowShade",
    attribute = "windowShade",
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      if pref.reverse then
        return data_types.Enum8(value == "closed" and 2 or value == "partially open" and 1 or 0)
      end
      return data_types.Enum8(value == "open" and 2 or value == "partially open" and 1 or 0)
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      local v = to_number(value)
      if pref.reverse then
        return v == 0 and "open" or v == 1 and "partially open" or "closed"
      end
      return v == 0 and "closed" or v == 1 and "partially open" or "open"
    end,
    command_to_value = function (self, command) return command.command == "open" and "open" or command.command == "pause" and "partially open" or "closed" end,
  },
  windowShadeLevel = {
    capability = "windowShadeLevel",
    attribute = "shadeLevel",
    rate_name = "rate",
    rate = 100,
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return tuya_types.Uint32(math.floor(to_number(value) * get_value(pref[self.rate_name], self.rate) / 100))
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate))
    end,
  },
  windowShadePreset = {
    capability = "windowShadePreset",
    attribute = "presetPosition",
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return tuya_types.Uint32(pref.reverse and (100 - pref.presetPosition) or pref.presetPosition)
    end,
    command_to_value = function (self, command) return command.command end,
  },
  value = {
    capability = "valleyboard16460.datapointValue",
    attribute = "value",
    rate_name = "rate",
    rate = 100,
    to_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return tuya_types.Uint32(math.floor(to_number(value) * get_value(pref[self.rate_name], self.rate) / 100))
    end,
    from_zigbee = function (self, value, device)
      local pref = get_child_or_parent(device, self.group).preferences
      return math.floor(100 * to_number(value) / get_value(pref[self.rate_name], self.rate))
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
    to_zigbee = function (self, value) return generic_body.GenericBody(value and unescape(value) or "") end,
    from_zigbee = function (self, value) return value and utils.get_print_safe_string(value) or "" end,
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
