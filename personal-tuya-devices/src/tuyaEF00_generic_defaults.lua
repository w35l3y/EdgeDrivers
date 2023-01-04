local log = require "log"
local utils = require "st.utils"

local zcl_clusters = require "st.zigbee.zcl.clusters"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local tuyaEF00_defaults = require "tuyaEF00_defaults"
local myutils = require "utils"

local capabilities = require "st.capabilities"
local info = capabilities["valleyboard16460.info"]

local datapoint_types_to_fn = {
  switchDatapoints = tuyaEF00_defaults.switch,
  switchLevelDatapoints = tuyaEF00_defaults.switchLevel,
  contactSensorDatapoints = tuyaEF00_defaults.contactSensor,
  doorControlDatapoints = tuyaEF00_defaults.doorControl,
  motionSensorDatapoints = tuyaEF00_defaults.motionSensor,
  presenceSensorDatapoints = tuyaEF00_defaults.presenceSensor,
  waterSensorDatapoints = tuyaEF00_defaults.waterSensors,
  enumerationDatapoints = tuyaEF00_defaults.enum,
  valueDatapoints = tuyaEF00_defaults.value,
  stringDatapoints = tuyaEF00_defaults.string,
  bitmapDatapoints = tuyaEF00_defaults.bitmap,
  rawDatapoints = tuyaEF00_defaults.raw,
}

local child_types_to_profile = {
  switchDatapoints = "child-switch-v1",
  switchLevelDatapoints = "child-switchLevel-v1",
  contactSensorDatapoints = "child-contactSensor-v1",
  doorControlDatapoints = "child-doorControl-v1",
  motionSensorDatapoints = "child-motionSensor-v1",
  presenceSensorDatapoints = "child-presenceSensor-v1",
  waterSensorDatapoints = "child-waterSensor-v1",
  enumerationDatapoints = "child-enum-v1",
  stringDatapoints = "child-string-v1",
  valueDatapoints = "child-value-v1",
  bitmapDatapoints = "child-bitmap-v1",
  rawDatapoints = "child-raw-v1",
}

local type_to_configuration = {
  [tuya_types.DatapointSegmentType.BOOLEAN] = "switch",
  [tuya_types.DatapointSegmentType.VALUE] = "value",
  [tuya_types.DatapointSegmentType.STRING] = "string",
  [tuya_types.DatapointSegmentType.ENUM] = "enumeration",
  [tuya_types.DatapointSegmentType.BITMAP] = "bitmap",
  [tuya_types.DatapointSegmentType.RAW] = "raw",
}

local function get_datapoints_from_device (device)
  local output,num = {},0
  for name, def in pairs(datapoint_types_to_fn) do
    if device.preferences[name] ~= nil then
      for dpid in device.preferences[name]:gmatch("[^,]+") do
        local ndpid = tonumber(dpid, 10)
        if output[ndpid] == nil then
          num=num+1
        end
        output[ndpid] = def
      end
    end
  end
  return output,num
end

local function get_datapoints_from_messages (list)
  local output,num = {},0
  for _, msg in pairs(list) do
    if output[list.dpid.value] == nil then
      num=num+1
    end
    output[list.dpid.value] = datapoint_types_to_fn[type_to_configuration[msg.type.value] .. "Datapoints"]
  end
  return output,num
end


local lifecycle_handlers = {}

local function create_child(driver, device, ndpid, profile)
  local dpid = string.format("%02X", ndpid)
  local created = device:get_child_by_parent_assigned_key(dpid)
  if not created then
    driver:try_create_device({
      type = "EDGE_CHILD",
      device_network_id = nil,
      parent_assigned_child_key = dpid,
      label = "Child " .. tonumber(dpid, 16),
      profile = profile,
      parent_device_id = device.id,
      manufacturer = driver.NAME,
      model = profile,
      vendor_provided_label = "Child " .. tonumber(dpid, 16),
    })
    --device:emit_event(datapoint_types_to_fn[name]:create_event(0))
  end
end

function lifecycle_handlers.infoChanged (driver, device, event, args)
  for name, profile in pairs(child_types_to_profile) do
    if device.preferences[name] ~= nil and args.old_st_store.preferences[name] ~= device.preferences[name] then
      for ndpid in device.preferences[name]:gmatch("[^,]+") do
        create_child(driver, device, ndpid, profile)
      end
    end
  end
end

local defaults = {
  lifecycle_handlers = lifecycle_handlers
}

function defaults.can_handle (opts, driver, device, ...)
  return device:supports_server_cluster(zcl_clusters.tuya_ef00_id)
end

local temporary_datapoints = {}

local function send_command(fn, driver, device, ...)
  if device.parent_device_id ~= nil then
    local datapoints,total = get_datapoints_from_device(device:get_parent_device())
    if total > 0 then
      fn(datapoints)(driver, device, ...)
    -- else
    --   fn(get_datapoints_from_messages(temporary_datapoints[device.id] or {}))(driver, device, ...)
    end
  end
end

local info = capabilities["valleyboard16460.info"]

function defaults.command_data_report_handler(driver, device, zb_rx)
  if temporary_datapoints[device.id] == nil then
    temporary_datapoints[device.id] = {}
  end
  if device.preferences ~= nil and device.preferences.updateInfo then
    local ndpid = zb_rx.body.zcl_body.data.dpid.value
    -- local _type = zb_rx.body.zcl_body.data.type
    -- local value = zb_rx.body.zcl_body.data.value.value
    temporary_datapoints[device.id][ndpid] = zb_rx.body.zcl_body.data
    device:emit_event(info.value(tostring(myutils.info(device, temporary_datapoints[device.id])), { visibility = { displayed = false } }))
  end
  -- create_child(driver, device, ndpid, child_types_to_profile[type_to_configuration[_type.value] .. "Datapoints"])
  -- tuyaEF00_defaults.command_data_report_handler(get_datapoints_from_messages(temporary_datapoints[device.id]))(driver, device, zb_rx)

  local datapoints,total = get_datapoints_from_device(device)
  if total > 0 then
    tuyaEF00_defaults.command_data_report_handler(datapoints)(driver, device, zb_rx)
  end
end

function defaults.command_true_handler(...)
  send_command(tuyaEF00_defaults.command_true_handler, ...)
end

function defaults.command_false_handler(...)
  send_command(tuyaEF00_defaults.command_false_handler, ...)
end

function defaults.command_switchLevel_handler(...)
  send_command(tuyaEF00_defaults.command_switchLevel_handler, ...)
end

function defaults.command_value_handler(...)
  send_command(tuyaEF00_defaults.command_value_handler, ...)
end

function defaults.command_string_handler(...)
  send_command(tuyaEF00_defaults.command_string_handler, ...)
end

function defaults.command_enum_handler(...)
  send_command(tuyaEF00_defaults.command_enum_handler, ...)
end

function defaults.command_bitmap_handler(...)
  send_command(tuyaEF00_defaults.command_bitmap_handler, ...)
end

function defaults.command_raw_handler(...)
  send_command(tuyaEF00_defaults.command_raw_handler, ...)
end

return defaults