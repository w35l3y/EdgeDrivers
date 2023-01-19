local log = require "log"
local utils = require "st.utils"

-- https://community.smartthings.com/t/st-edge-change-driver-tool-in-the-st-app/230956/23?u=w35l3y
local base_device = require "st.device"
local device_management = require "st.zigbee.device_management"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local data_types = require "st.zigbee.data_types"

local myutils = require "utils"

local cluster_base = require "st.zigbee.cluster_base"
local read_attribute = require "st.zigbee.zcl.global_commands.read_attribute"
local zcl_messages = require "st.zigbee.zcl"
local messages = require "st.zigbee.messages"
local zb_const = require "st.zigbee.constants"

function cluster_base.read_attributes(device, cluster_id, attr_ids)
  local read_body = read_attribute.ReadAttribute(attr_ids)
  local zclh = zcl_messages.ZclHeader({
    cmd = data_types.ZCLCommandId(read_attribute.ReadAttribute.ID)
  })
  local addrh = messages.AddressHeader(
      zb_const.HUB.ADDR,
      zb_const.HUB.ENDPOINT,
      device:get_short_address(),
      device:get_endpoint(cluster_id.value),
      zb_const.HA_PROFILE_ID,
      cluster_id.value
  )
  local message_body = zcl_messages.ZclMessageBody({
    zcl_header = zclh,
    zcl_body = read_body
  })
  return messages.ZigbeeMessageTx({
    address_header = addrh,
    body = message_body
  })
end

-- set_component_to_endpoint_fn
-- get_endpoint_for_component_id
-- utilizado quando enviado comando device:send_to_component
-- este comando acima é comumento utilizado quando clicamos numa ação do app
local function component_to_endpoint(device, component_id)
  if component_id == "main" and myutils.is_normal(device) then
    return device.fingerprinted_endpoint_id
  else
    local group = component_id:match("main(%x+)")
    return group and tonumber(group, 16) or device.fingerprinted_endpoint_id
  end
end

-- set_endpoint_to_component_fn
-- get_component_id_for_endpoint
-- utilizado quando enviado comando device:emit_event_for_endpoint
-- este comando acima é comumente utilizado quando clicamos num botão físico (recepção de attributo)
-- @TODO pode ser que eu precise atualizar o handler global para emitir este evento
local function endpoint_to_component(device, group)
  if group == device.fingerprinted_endpoint_id and myutils.is_normal(device) then
    return "main"
  else
    return string.format("main%02X", group)
  end
end

local function find_child_fn(device, group)
  return device:get_child_by_parent_assigned_key(string.format("%02X", group))
end

local lifecycles = {}

function lifecycles.init(driver, device, event, ...)
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)
  device:set_find_child(find_child_fn)

  -- tuya magic spell
  device:send(cluster_base.read_attributes(device, data_types.ClusterId(zcl_clusters.Basic.ID), {
    data_types.AttributeId(zcl_clusters.Basic.attributes.ManufacturerName.ID),
    data_types.AttributeId(zcl_clusters.Basic.attributes.ZCLVersion.ID),
    data_types.AttributeId(zcl_clusters.Basic.attributes.ApplicationVersion.ID),
    data_types.AttributeId(zcl_clusters.Basic.attributes.ModelIdentifier.ID),
    data_types.AttributeId(zcl_clusters.Basic.attributes.PowerSource.ID),
    data_types.AttributeId(0xFFFE),
  }))
end

function lifecycles.added(driver, device, event, ...)
  local ep_supports_server_cluster = function(cluster_id, ep)
    -- if not ep then return false end
    for _, cluster in ipairs(ep.server_clusters) do
      if cluster == cluster_id then
        return true
      end
    end
    return false
  end

  if device.preferences.profile == "normal_multi_switch_v1" then
    for _, ep in pairs(device.zigbee_endpoints) do
      if ep.id ~= device.fingerprinted_endpoint_id and ep_supports_server_cluster(zcl_clusters.OnOff.ID, ep) then
        myutils.create_child(driver, device, ep.id, "child-switch-v1")
      end
    end
  elseif device.preferences.profile == "normal_multi_dimmer_v1" then
    for _, ep in pairs(device.zigbee_endpoints) do
      if ep.id ~= device.fingerprinted_endpoint_id and ep_supports_server_cluster(zcl_clusters.Level.ID, ep) then
        myutils.create_child(driver, device, ep.id, "child-dimmer-v1")
      end
    end
  end
end

function lifecycles.removed(driver, device, event, ...)
end

--function lifecycles.doConfigure(driver, device, event, args)
--  device_management.configure(driver, device)
--end

return lifecycles
