local log = require "log"
local utils = require "st.utils"

local device_lib = require "st.device"

local myutils = require "utils"
local tuyaEF00_defaults = require "tuyaEF00_defaults"
local REPORT_BY_DP = {}

local mt = {}
mt.__cluster_cache = {}
mt.__index = function(self, key)
  if mt.__cluster_cache[key] == nil then
    -- @FIXME Update to load device on demand, not the whole model
    -- It will require a file for each model+manufacturer
    local ok, result = pcall(myutils.load_model_from_json, key)
    mt.__cluster_cache[key] = ok and result or {}
    if not ok then
      log.error(result)
    end
  end
  return mt.__cluster_cache[key]
end
setmetatable(REPORT_BY_DP, mt)

local function get_default_by_profile (device)
  for model, devices in pairs(mt.__cluster_cache) do
    for mfr, dp in pairs(devices) do
      for _, profile in ipairs(dp.profiles) do
        if device.parent_assigned_child_key ~= nil and profile == device:get_parent_device().preferences.profile or profile == device.preferences.profile then
          log.warn("Simulating device", mfr, model)
          return dp
        end
      end
    end
  end
end
local function send_command(fn, driver, device, ...)
  local dp = REPORT_BY_DP[device:get_model()][device:get_manufacturer()] or get_default_by_profile(device)
  if dp ~= nil then
    fn(dp.datapoints)(driver, device, ...)
  end
end

local lifecycle_handlers = utils.merge({}, require "lifecycles")

function lifecycle_handlers.infoChanged(driver, device, event, args)
  if args.old_st_store.preferences.profile ~= device.preferences.profile or (not myutils.is_normal(device) and device.profile.components.main == nil) then
    device:try_update_metadata({
      profile = device.preferences.profile:gsub("_", "-")
    })
  end
  
  if device.network_type == device_lib.NETWORK_TYPE_ZIGBEE then
    for name, value in pairs(device.preferences) do
      if value and value ~= args.old_st_store.preferences[name] then
        local normalized_id = utils.snake_case(name)
        local match, _length, pref, component, group = string.find(normalized_id, "^child(_?%w*)_(main(%x+))$")
        if match ~= nil then
          local profile = ("child" .. (pref ~= "" and pref or "_switch") .. "-v1"):gsub("_", "-")
          myutils.create_child(driver, device, tonumber(group, 16), profile)
          -- local created = device:get_child_by_parent_assigned_key(group)
          -- if not created then
          --   driver:try_create_device({
          --     type = "EDGE_CHILD",
          --     device_network_id = nil,
          --     parent_assigned_child_key = group,
          --     label = "Child " .. tonumber(group, 16),
          --     profile = profile,
          --     parent_device_id = device.id,
          --     manufacturer = driver.NAME,
          --     model = profile,
          --     vendor_provided_label = "Child " .. tonumber(group, 16),
          --   })
          -- end
          goto next
        end
        local match, _length, key = string.find(normalized_id, "^pref_([%w_]+)$")
        if match ~= nil then
          send_command(tuyaEF00_defaults.update_data, driver, device, key, value)
          goto next
        end
      end
      ::next::
    end
  end
end

local defaults = {
  lifecycle_handlers = lifecycle_handlers,
}

function defaults.can_handle (opts, driver, device, ...)
  if device.preferences.profile ~= "generic_ef00_v1" then
    if REPORT_BY_DP[device:get_model()][device:get_manufacturer()] ~= nil then
      return true
    end
    -- for mfr, dp in pairs(REPORT_BY_DP[device:get_model()]) do
    --   if mfr == device:get_manufacturer() then
    --     return true
    --   end
    -- end
    for model, devices in pairs(mt.__cluster_cache) do
      for mfr, dp in pairs(devices) do
        for _, profile in ipairs(dp.profiles) do
          if device.parent_assigned_child_key ~= nil and profile == device:get_parent_device().preferences.profile or profile == device.preferences.profile then
            -- log.warn("Simulating device", mfr, model)
            return true
          end
        end
      end
    end
    log.warn("Similar device not found", device.preferences.profile)
  end
  return false
end

function defaults.command_response_handler(...)
  send_command(tuyaEF00_defaults.command_response_handler, ...)
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