local log = require "log"
local utils = require "st.utils"

local capabilities = require "st.capabilities"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"
local generic_body = require "st.zigbee.generic_body"

local commands = require "commands"
local settings = capabilities["valleyboard16460.settings"]

local myutils = require "utils"

local map_to_fn = {
  [tuya_types.DatapointSegmentType.BOOLEAN] = commands.switch,
  [tuya_types.DatapointSegmentType.VALUE] = commands.value,
  [tuya_types.DatapointSegmentType.STRING] = commands.string,
  [tuya_types.DatapointSegmentType.ENUM] = commands.enum,
  [tuya_types.DatapointSegmentType.BITMAP] = commands.bitmap,
  [tuya_types.DatapointSegmentType.RAW] = commands.raw,
}

local defaults = {}

local function get_value(data)
  if getmetatable(data) == generic_body.GenericBody then
    return data:_serialize()
  end
  return data.value
end

local map_cap_to_pref = {
  ["valleyboard16460.datapointValue"] = "value",
  ["valleyboard16460.datapointString"] = "string",
  ["valleyboard16460.datapointEnum"] = "enum",
  ["valleyboard16460.datapointBitmap"] = "bitmap",
  ["valleyboard16460.datapointRaw"] = "raw",
}

local function get_dp(dp, def, device)
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
end

function defaults.command_synctime_handler(driver, device, zb_rx)
  -- device:send(zcl_clusters.TuyaEF00.commands.McuSyncTime(device))
  log.info("McuSyncTime", zb_rx:pretty_print())
end

function defaults.command_gatestatus_handler(driver, device, zb_rx)
  device:send(zcl_clusters.TuyaEF00.commands.GatewayStatusResponse(device, zb_rx.body.zcl_body.data.value))
  -- log.info("GatewayStatusRequest", zb_rx:pretty_print())
end

function defaults.fallback_handler (driver, device, zb_rx)
  log.debug("DEFAULT FALLBACK", zb_rx:pretty_print())
end

function defaults.command_response_handler(datapoints)
  return function (driver, device, zb_rx)
    -- device.parent_assigned_child_key chega sempre nulo
    local dpid = zb_rx.body.zcl_body.data.dpid.value
    local _type = zb_rx.body.zcl_body.data.type.value

    local event_dp = datapoints[dpid]
    local dp_pref_temp = event_dp and get_dp(nil, event_dp, device) or nil
    if dp_pref_temp == 0 or dp_pref_temp == dpid then
      log.info("Default datapoint", dpid, dp_pref_temp)
    else
      local pref_found = false
      for index_pref, event_pref in pairs(datapoints) do
        local dp_pref = get_dp(nil, event_pref, device)
        if dpid == dp_pref then
          pref_found = true
          if dp_pref_temp and index_pref ~= dp_pref_temp then
            log.warn("Datapoint overridden", dpid, dp_pref_temp, index_pref)
          else
            log.info("Datapoint overridden", dpid, dp_pref_temp, index_pref)
          end
          event_dp = event_pref
          break
        end
      end
      if not pref_found and dp_pref_temp then
        event_dp = nil
        log.warn("Datapoint settings rejected", dpid, dp_pref_temp)
      end
    end

    if not event_dp then
      log.warn("Datapoint not found. Using default", dpid)
      event_dp = map_to_fn[_type]({group=dpid}) or commands.generic
    end
    local value = get_value(zb_rx.body.zcl_body.data.value)
    local event = event_dp:create_event(value, device)
    local cur_time = os.time()
    
    --log.info("device.preferences.profile", device.preferences.profile)
    if event then
      if not event_dp.reportingInterval or not event_dp.last_heard_time or cur_time - event_dp.last_heard_time >= 60 * event_dp.reportingInterval then
        event_dp.last_heard_time = cur_time
        if event_dp.name then
          local pref_name = utils.camel_case("pref_"..event_dp.name)
          log.info("pref_name", pref_name, device:get_field(pref_name), "-")
          device:set_field(pref_name, event_dp:from_zigbee(value, device))
          -- device.st_store.preferences[pref_name] = event_dp:from_zigbee(value, device)
          if device:supports_capability_by_id(settings.ID) then
            device:emit_event(settings.value(tostring(myutils.settings(device))))
          end
        end
        -- atualiza o child caso exista
        local status, e, err = pcall(device.emit_event_for_endpoint, device, event_dp.group or dpid, event)
        -- quando e == nil, significa que encontrou child
        -- como preciso atualizar o parent também, daí tem a lógica abaixo
        if e == nil and err == nil then
          -- atualiza o parent
          local comp_id = device:get_component_id_for_endpoint(event_dp.group or dpid)
          local comp = device.profile.components[comp_id]
          if comp then
            device:emit_component_event(comp, event)
          end
        elseif not status or err then
          log.warn("Unexpected component for datapoint", event_dp.group, dpid, value, e, err)
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
        log.info("Too quick! Do nothing.", dpid, value, event_dp.reportingInterval, cur_time, event_dp.last_heard_time, "-")
      end
    else
      log.warn("Unexpected datapoint.", dpid, value)
    end
  end
end

function defaults.update_data(datapoints)
  return function (driver, device, name, value)
    for dpid, def in pairs(datapoints) do
      if def.name == name then
        device:send(zcl_clusters.TuyaEF00.commands.DataRequest(device, get_dp(dpid, def, device), def:to_zigbee(value, device)))
        break
      end
    end
  end
end

local function send_command(datapoints, device, command, value_fn)
  -- log.info("send_command")
  if device.parent_assigned_child_key == nil then
    if command.component ~= "main" or myutils.is_normal(device) then
      -- log.info("entrou 1")
      local group = device:get_endpoint_for_component_id(command.component)
      for dpid, def in pairs(datapoints) do
        -- log.info("Datapoint 1", def.capability, command.capability, dpid, def.group, group)
        if group == def.group and command.capability == def.capability then
          device:send(zcl_clusters.TuyaEF00.commands.DataRequest(device, math.abs(get_dp(dpid, def, device)), def:command_handler(command, device)))
          break
        end
      end
    else
      -- log.info("entrou 2")
      for dpid, def in pairs(datapoints) do
        -- log.info("Datapoint 2", def.capability, command.capability, dpid, def.group)
        if command.capability == def.capability then
          device:send(zcl_clusters.TuyaEF00.commands.DataRequest(device, math.abs(get_dp(dpid, def, device)), def:command_handler(command, device)))
        end
      end
    end
  else
    local group = tonumber(device.parent_assigned_child_key, 16)
    for dpid, def in pairs(datapoints) do
      if group == def.group and command.capability == def.capability then
        -- este comando abaixo delega pro get_parent_device()
        device:send(zcl_clusters.TuyaEF00.commands.DataRequest(device:get_parent_device(), math.abs(get_dp(dpid, def, device)), def:command_handler(command, device)))
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