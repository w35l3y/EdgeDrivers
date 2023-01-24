local log = require "log"
local utils = require "st.utils"

local capabilities = require "st.capabilities"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

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

function defaults.command_response_handler(datapoints)
  return function (driver, device, zb_rx)
    -- device.parent_assigned_child_key chega sempre nulo
    local dpid = zb_rx.body.zcl_body.data.dpid.value
    local value = zb_rx.body.zcl_body.data.value.value
    local _type = zb_rx.body.zcl_body.data.type.value
    local event_dp = datapoints[dpid] or map_to_fn[_type]({group=dpid}) or commands.generic
    local event = event_dp:create_event(value, device)
    local cur_time = os.time()
    
    --log.info("device.preferences.profile", device.preferences.profile)
    if event ~= nil then
      if event_dp.reportingInterval == nil or cur_time - (event_dp.last_heard_time or 0) > 60 * event_dp.reportingInterval then
        event_dp.last_heard_time = cur_time
        if event_dp.name ~= nil then
          local pref_name = utils.camel_case("pref_"..event_dp.name)
          log.info("pref_name", pref_name, device:get_field(pref_name), "-")
          device:set_field(pref_name, event_dp:from_zigbee(value, device))
          -- device.st_store.preferences[pref_name] = event_dp:from_zigbee(value, device)
          device:emit_event(settings.value(tostring(myutils.settings(device))))
        end
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
          log.warn("Unexpected component for datapoint", event_dp.group, dpid, value, e)
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
        log.info("Too quick! Do nothing.", dpid, value, event_dp.reportingInterval)
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
        device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device, dpid, def:to_zigbee(value, device)))
        break
      end
    end
  end
end

local function send_command(datapoints, device, command, value_fn)
  if device.parent_assigned_child_key == nil then
    if command.component ~= "main" or myutils.is_normal(device) then
      local group = device:get_endpoint_for_component_id(command.component)
      for dpid, def in pairs(datapoints) do
        if group == def.group and command.capability == def.capability then
          device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device, dpid, def:command_handler(command, device)))
          break
        end
      end
    else
      for dpid, def in pairs(datapoints) do
        if command.capability == def.capability then
          device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device, dpid, def:command_handler(command, device)))
        end
      end
    end
  else
    local group = tonumber(device.parent_assigned_child_key, 16)
    for dpid, def in pairs(datapoints) do
      if group == def.group and command.capability == def.capability then
        -- este comando abaixo delega pro get_parent_device()
        device:send(zcl_clusters.TuyaEF00.server.commands.DataRequest(device:get_parent_device(), dpid, def:command_handler(command, device)))
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