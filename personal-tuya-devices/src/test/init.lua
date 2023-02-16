require "test.generic-ef00-v1"
require "test.normal-multi-switch-v1"
require "test.custom-multi-switch-v4"
require "test.normal-multi-switch-v4"
require "test.switch-all-multi-switch-v4"
require "test.custom-multi-switch-v6"
require "test.normal-multi-switch-v6"
require "test.switch-all-multi-switch-v6"
require "test.normal-multi-dimmer-v1"
require "test.custom-multi-dimmer-v2"
require "test.normal-multi-dimmer-v2"
require "test.switch-all-multi-dimmer-v2"
require "test.normal-air-quality-v1"
require "test.normal-air-quality-v2"
require "test.normal-thermostat-v1"
require "test.normal-single-dimmer-v1"
require "test.normal-presenceSensor-v1"
require "test.normal-garage-door-v1"
require "test.normal-powerMeter-v1"
require "test.normal-irrigation-v1"

local test = require "integration_test"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local profile = t_utils.get_profile_definition("generic-ef00-v1.yaml")

test.load_all_caps_from_profile(profile)
test.load_all_caps_from_profile(t_utils.get_profile_definition("child-enum-v1.yaml"))
test.load_all_caps_from_profile(t_utils.get_profile_definition("child-value-v1.yaml"))
test.load_all_caps_from_profile(t_utils.get_profile_definition("child-string-v1.yaml"))
test.load_all_caps_from_profile(t_utils.get_profile_definition("child-bitmap-v1.yaml"))
test.load_all_caps_from_profile(t_utils.get_profile_definition("child-raw-v1.yaml"))

zigbee_test_utils.prepare_zigbee_env_info()

test.set_test_init_function(function()
  error("You must use your own `test_init`")
end)

local result = test.run_registered_tests()
if result == nil or result.failed > 0 then
  error("Unable to proceed")
end