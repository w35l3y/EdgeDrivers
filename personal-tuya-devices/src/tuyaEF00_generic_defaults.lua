local log = require "log"
local utils = require "st.utils"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local device_lib = require "st.device"

local tuyaEF00_defaults = require "tuyaEF00_defaults"
local myutils = require "utils"

local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"
local commands = require "commands"

local capabilities = require "st.capabilities"
local info = capabilities["valleyboard16460.info"]

local datapoint_types_to_fn = {
  switchDatapoints = commands.switch,
  switchLevelDatapoints = commands.switchLevel,
  airQualitySensDatapoints = commands.airQualitySensor,
  alarmDatapoints = commands.alarm,
  audioMuteDatapoints = commands.audioMute,
  audioVolumeDatapoints = commands.audioVolume,
  batteryDatapoints = commands.battery,
  buttonDatapoints = commands.button,
  carbonDioxideMDatapoints = commands.carbonDioxideMeasurement,
  contactSensorDatapoints = commands.contactSensor,
  currentMeasureDatapoints = commands.currentMeasurement,
  doorControlDatapoints = commands.doorControl,
  dustSensorDatapoints = commands.dustSensor,
  energyMeterDatapoints = commands.energyMeter,
  fineDustSensorDatapoints = commands.fineDustSensor,
  gasDetectorDatapoints = commands.gasDetector,
  veryFineDustSeDatapoints = commands.veryFineDustSensor,
  formaldehydeMeDatapoints = commands.formaldehydeMeasurement,
  humidityMeasurDatapoints = commands.relativeHumidityMeasurement,
  illuminanceMeaDatapoints = commands.illuminanceMeasurement,
  keypadInputDatapoints = commands.keypadInput,
  motionSensorDatapoints = commands.motionSensor,
  occupancySensoDatapoints = commands.occupancySensor,
  powerMeterDatapoints = commands.powerMeter,
  presenceSensorDatapoints = commands.presenceSensor,
  smokeDetectorDatapoints = commands.smokeDetector,
  temperatureMeaDatapoints = commands.temperatureMeasurement,
  thermostatCoolDatapoints = commands.thermostatCoolingSetpoint,
  thermostatHeatDatapoints = commands.thermostatHeatingSetpoint,
  thermostatModeDatapoints = commands.thermostatMode,
  thermostatOperDatapoints = commands.thermostatOperatingState,
  tvocMeasuremenDatapoints = commands.tvocMeasurement,
  valveDatapoints = commands.valve,
  voltageMeasureDatapoints = commands.voltageMeasurement,
  waterSensorDatapoints = commands.waterSensor,
  windowShadeDatapoints = commands.windowShade,
  windowShadeLevDatapoints = commands.windowShadeLevel,
  windowShadePreDatapoints = commands.windowShadePreset,
  enumerationDatapoints = commands.enum,
  valueDatapoints = commands.value,
  stringDatapoints = commands.string,
  bitmapDatapoints = commands.bitmap,
  rawDatapoints = commands.raw,
}

local child_types_to_profile = {
  switchDatapoints = "child-switch-v1",
  switchLevelDatapoints = "child-switchLevel-v1",
  airQualitySensDatapoints = "child-airQualitySensor-v1",
  alarmDatapoints = "child-alarm-v1",
  audioMuteDatapoints = "child-audioMute-v1",
  audioVolumeDatapoints = "child-audioVolume-v1",
  batteryDatapoints = "child-battery-v1",
  buttonDatapoints = "child-button-v1",
  carbonDioxideMDatapoints = "child-carbonDioxideMeasurement-v1",
  contactSensorDatapoints = "child-contactSensor-v1",
  currentMeasureDatapoints = "child-currentMeasurement-v1",
  doorControlDatapoints = "child-doorControl-v1",
  dustSensorDatapoints = "child-dustSensor-v1",
  energyMeterDatapoints = "child-energyMeter-v1",
  fineDustSensorDatapoints = "child-fineDustSensor-v1",
  gasDetectorDatapoints = "child-gasDetector-v1",
  veryFineDustSeDatapoints = "child-veryFineDustSensor-v1",
  formaldehydeMeDatapoints = "child-formaldehydeMeasurement-v1",
  humidityMeasurDatapoints = "child-relativeHumidityMeasurement-v1",
  illuminanceMeaDatapoints = "child-illuminanceMeasurement-v1",
  keypadInputDatapoints = "child-keypadInput-v1",
  motionSensorDatapoints = "child-motionSensor-v1",
  occupancySensoDatapoints = "child-occupancySensor-v1",
  powerMeterDatapoints = "child-powerMeter-v1",
  presenceSensorDatapoints = "child-presenceSensor-v1",
  smokeDetectorDatapoints = "child-smokeDetector-v1",
  temperatureMeaDatapoints = "child-temperatureMeasurement-v1",
  thermostatCoolDatapoints = "child-thermostatCoolingSetpoint-v1",
  thermostatHeatDatapoints = "child-thermostatHeatingSetpoint-v1",
  thermostatModeDatapoints = "child-thermostatMode-v1",
  thermostatOperDatapoints = "child-thermostatOperatingState-v1",
  tvocMeasuremenDatapoints = "child-tvocMeasurement-v1",
  valveDatapoints = "child-valve-v1",
  voltageMeasureDatapoints = "child-voltageMeasurement-v1",
  waterSensorDatapoints = "child-waterSensor-v1",
  windowShadeDatapoints = "child-windowShade-v1",
  windowShadeLevDatapoints = "child-windowShadeLevel-v1",
  windowShadePreDatapoints = "child-windowShadePreset-v1",
  enumerationDatapoints = "child-enum-v1",
  valueDatapoints = "child-value-v1",
  stringDatapoints = "child-string-v1",
  bitmapDatapoints = "child-bitmap-v1",
  rawDatapoints = "child-raw-v1",
}

local type_to_configuration = {
  [tuya_types.DatapointSegmentType.BOOLEAN] = "switchDatapoints",
  [tuya_types.DatapointSegmentType.VALUE] = "valueDatapoints",
  [tuya_types.DatapointSegmentType.STRING] = "stringDatapoints",
  [tuya_types.DatapointSegmentType.ENUM] = "enumerationDatapoints",
  [tuya_types.DatapointSegmentType.BITMAP] = "bitmapDatapoints",
  [tuya_types.DatapointSegmentType.RAW] = "rawDatapoints",
}

local constants = {
  FORCE_EF00_CLUSTER = "FORCE_EF00_CLUSTER",
}

local function get_datapoints_from_device (device)
  local output,num = {},0
  for name, def in pairs(datapoint_types_to_fn) do
    if device.preferences[name] then
      for dpid in device.preferences[name]:gmatch("[^,]+") do
        local ndpid = tonumber(dpid, 10)
        if output[ndpid] == nil then
          num=num+1
        end
        output[ndpid] = def({group=ndpid})
      end
    end
  end
  return output,num
end

local function get_datapoints_from_messages (list)
  local output,num = {},0
  for _, zb_rx in pairs(list) do
    for i, body in ipairs(zb_rx.body.zcl_body.data_list) do
      if output[body.dpid.value] == nil then
        num=num+1
      end
      output[body.dpid.value] = datapoint_types_to_fn[type_to_configuration[body.type.value]]({group=body.dpid.value})
    end
  end
  return output,num
end

local temporary_datapoints = {}

local function send_command(fn, driver, device, ...)
  local datapoints,total = get_datapoints_from_device(device.parent_assigned_child_key and device:get_parent_device() or device)
  if total > 0 then
    fn(datapoints)(driver, device, ...)
  end
end

local lifecycle_handlers = utils.merge({}, require "lifecycles")

function lifecycle_handlers.added(driver, device, event, ...)
  if device.network_type == device_lib.NETWORK_TYPE_ZIGBEE then
    device:set_field(constants.FORCE_EF00_CLUSTER, true, { persist = true })
    -- device:send(zcl_clusters.TuyaEF00.commands.McuSyncTime(device))
    device.thread:call_with_delay(15, function()
      myutils.log(device, "debug", "--- GatewayData -----------------------------------")
      device:send(zcl_clusters.TuyaEF00.commands.GatewayData(device))
    end)
  elseif device.network_type == device_lib.NETWORK_TYPE_CHILD then
    local tmp = temporary_datapoints[device.parent_device_id]
    local dpid = tonumber(device.parent_assigned_child_key, 16)
    if tmp and tmp[dpid] then
      send_command(tuyaEF00_defaults.command_response_handler, driver, device:get_parent_device(), {body={zcl_body={data_list={tmp[dpid]}}}})
    else
      myutils.log(device, "warn", "Unable to update status of newly added child device", device.parent_assigned_child_key, device.parent_device_id, dpid, tmp and true or false)
    end
  end
end

function lifecycle_handlers.infoChanged (driver, device, event, args)
  -- if args.old_st_store.preferences.logLevel ~= device.preferences.logLevel then
  --   log.set_log_level(device.preferences.logLevel)
  -- end
  if args.old_st_store.preferences.profile ~= device.preferences.profile then
    myutils.log(device, "debug", "Profile changed...", args.old_st_store.preferences.profile, device.preferences.profile)
    local p = device.preferences.profile:gsub("_", "-")
    device:set_field("profile", p, { persist = true })
    device:try_update_metadata({
      profile = p
    })
  end

  if device.network_type == device_lib.NETWORK_TYPE_ZIGBEE then
    for name, value in utils.pairs_by_key(device.preferences) do
      local profile = child_types_to_profile[name]
      if profile and value and value ~= args.old_st_store.preferences[name] then
        for ndpid in value:gmatch("[^,]+") do
          myutils.create_child(driver, device, tonumber(ndpid, 10), profile)
        end
      end
    end
  else
    for name, value in utils.pairs_by_key(device.preferences) do
      if value ~= nil and args.old_st_store.preferences[name] ~= value then
        myutils.log(device, "debug", "Preference changed...", name, args.old_st_store.preferences[name], value)
      end
    end
  end
end

-- devices that use 0xEF00 but doesn't expose it
local exceptions = {
  "_TZE200_pay2byax",
  "_TZE200_znbl8dj5"
}

local function in_exception_list (device)
  for _,mfr in ipairs(exceptions) do
    if mfr == device:get_manufacturer() then
      return true
    end
  end
  return false
end

local defaults = {
  lifecycle_handlers = lifecycle_handlers,
  command_synctime_handler = tuyaEF00_defaults.command_synctime_handler,
  command_gatestatus_handler = tuyaEF00_defaults.command_gatestatus_handler,
  fallback_handler = function (driver, device, zb_rx)
    myutils.log(device, "debug", "GENERIC FALLBACK", zb_rx:pretty_print())
  end,
}

function defaults.can_handle (opts, driver, device, o, ...)
  -- log.debug("can_handle", device:get_field(constants.FORCE_EF00_CLUSTER), o, utils.stringify_table({...}))
  return device:supports_server_cluster(zcl_clusters.tuya_ef00_id) or in_exception_list(device) or myutils.is_profile(device, "generic_ef00_v1") or device:get_field(constants.FORCE_EF00_CLUSTER) or not (myutils.is_profile(device, "normal_multi_switch_v1") or myutils.is_profile(device, "normal_multi_dimmer_v1"))
end

function defaults.command_response_handler(driver, device, zb_rx)
  if temporary_datapoints[device.id] == nil then
    temporary_datapoints[device.id] = {}
  end
  if device.preferences and device.preferences.updateInfo then
    for i,data in ipairs(zb_rx.body.zcl_body.data_list) do
      local ndpid = data.dpid.value
      temporary_datapoints[device.id][ndpid] = data
      device:emit_event(info.value(tostring(myutils.info(device, temporary_datapoints[device.id])), { visibility = { displayed = false } }))
    end
  end

  send_command(tuyaEF00_defaults.command_response_handler, driver, device, zb_rx)
end

function defaults.capability_handler(...)
  send_command(tuyaEF00_defaults.capability_handler, ...)
end

function defaults.register_for_default_handlers(driver, capabilities)
  driver.capability_handlers = driver.capability_handlers or {}
  for _,cap in ipairs(capabilities) do
    driver.capability_handlers[cap.ID] = driver.capability_handlers[cap.ID] or {}
    for _,command in pairs(cap.commands) do
      driver.capability_handlers[cap.ID][command.NAME] = driver.capability_handlers[cap.ID][command.NAME] or defaults.capability_handler
    end
  end
end

return defaults