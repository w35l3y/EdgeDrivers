require "test.generic-ef00-v1"
require "test.normal-multi-switch-v1"
require "test.normal-multi-switch-v4"
require "test.normal-multi-switch-v6"
require "test.normal-multi-dimmer-v1"
require "test.normal-multi-dimmer-v2"
require "test.normal-air-quality-v1"
require "test.normal-air-quality-v2"
require "test.normal-thermostat-v1"
require "test.normal-single-dimmer-v1"
require "test.normal-presenceSensor-v1"
require "test.normal-garage-door-v1"

local test = require "integration_test"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

zigbee_test_utils.prepare_zigbee_env_info()

test.set_test_init_function(function()
  error("You must use your own `test_init`")
end)

local result = test.run_registered_tests()
if result == nil or result.failed > 0 then
  error("Unable to proceed")
end