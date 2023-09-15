- [SmartThings Community Discussion](https://community.smartthings.com/t/st-edge-personal-tuya-devices-generic-ef00-device/255270?u=w35l3y)
- [Invitation link](https://api.smartthings.com/invite/6Vjd4YPVJwjN)

## How to use

This driver is intended to work with devices that use **0xEF00** Tuya Cluster

### Install the driver

1. Accept the invitation ( https://api.smartthings.com/invite/6Vjd4YPVJwjN )
2. Enroll the hub
3. List available drivers
4. Install the driver ( Personal Tuya Devices )

### Pair the device

1. Open SmartThings App
2. Search for nearby devices
3. Set the device in pairing mode

<img src="resources/pairing_1.jpeg" height="300"/> <img src="resources/pairing_2.jpeg" height="300"/> <img src="resources/pairing_3.jpeg" height="300"/> <img src="resources/dashboard_1.jpeg" height="300"/>

### Configure for similarity - beginner mode (only if your device was not recognized automatically and you want to test a predefined device)

1. Open the detail view of the device
2. Open configurations
3. Select the profile that best match with the type of your device and confirm

If it doesn't update the profile, please read Known issues.

<img src="resources/generic_profiles.jpeg" height="300"/>

### Configure datapoints - advanced mode (only if your device was not recognized automatically)

1. Open the detail view of the device
2. Open configurations
3. Fill the fields that best match the specified for your device
   - Search on the internet about your device details (manufacturer and model)
   - You will find the same device or very similar ones working on other systems (Home Assistant, Hubitat, old Groovy DTHs, ...)
   - Similar devices usually use the same datapoints (it is NOT a rule!)
   - There are configurations for some stock capabilities<br />
     Currently: switch, switchLevel, airQualitySensor, alarm, audioMute, audioVolume, battery, button, carbonDioxideMeasurement, contactSensor, currentMeasurement, doorControl, dustSensor, energyMeter, fineDustSensor, gasDetector, formaldehydeMeasurement, illuminanceMeasurement, keypadInput, motionSensor, occupancySensor, powerMeter, presenceSensor, relativeHumidityMeasurement, temperatureMeasurement, thermostatCoolingSetpoint, thermostatHeatingSetpoint, thermostatMode, thermostatOperatingState, tvocMeasurement, valve, veryFineDustSensor, voltageMeasurement, waterSensor/leakSensor, windowShade, windowShadeLevel and windowShadePreset
   - Also, there are configurations for generic Tuya Data Types<br />
     Currently: boolean (switch/binary sensors), enumeration, value, string, bitmap and raw
   - For example:
     - If you know the datapoint 1 is for a writable boolean (actuator), then add it to "Datapoints for switches"
     - If you know the datapoint 2 is for a read-only boolean (sensor), then add it to any binary sensor

<img src="resources/detailView_1.jpeg" height="300"/> <img src="resources/configuration_1.jpeg" height="300"/> <img src="resources/configuration_2.jpeg" height="300"/> <img src="resources/dashboard_2.jpeg" height="300"/> <img src="resources/child_detailView_2.jpeg" height="300"/>

## Contribute with your integration

1. Once you know exactly how your device works with each available datapoints, consider forking the repository and adding the code needed to make it a little more user friendly.
2. Create a file representing your device at `/models/<model>/<manufacturer>.yaml`<br />
   - You may use any of the existing files as template.
   - Possible commands are at `/src/commands.lua`.
   - If you need a new profile, then create it at `/profiles/normal-XXXXXXXXXXXXXXXXX-vX.yaml`
3. Execute `npm start` to test locally
   - All required files are created/modified with this command.
   - Don't bother modifying `fingerprints.yaml` manually.
   - Re-execute it every time you modify your model file to create/modify files properly. Otherwise, you may have inconsistent results.
4. Pull request your modification

### Examples of including predefined devices:

- https://github.com/w35l3y/EdgeDrivers/commit/c8afcfc759c8114b53693f5095b1059a8c679ea6 (new profile + unit tests)
- https://github.com/w35l3y/EdgeDrivers/commit/47b55df44d73fb6faf3db1b5e6965aadf2c62ac7
- https://github.com/w35l3y/EdgeDrivers/commit/9b9448c8f46ec47a82034809d7a25c580df7d4cf (new profile)
- https://github.com/w35l3y/EdgeDrivers/commit/e51cd5fcd3a2e096d2289074a3a44c976348ec93
- https://github.com/w35l3y/EdgeDrivers/commit/0fe4849b5bffe7b52bac84cbc71a55b6bae3b0a5
- Each file here is an example: https://github.com/w35l3y/EdgeDrivers/tree/beta/personal-tuya-devices/models/TS0601

Once you include/modify your model file, execute the command `npm start` to generate other files.

### Examples of including new stock capabilities:

- https://github.com/w35l3y/EdgeDrivers/commit/f76feeca83ab707abe9f2ba6b0f0ae682a14a099 (+ unit tests)
- https://github.com/w35l3y/EdgeDrivers/commit/ad5aad2f4842a5fe6195777aece3cf15fd4a31c9 (+ unit tests)
- https://github.com/w35l3y/EdgeDrivers/commit/c0925db83c50985368b52ab76d1694aefc4deb79 (+ unit tests)
- https://github.com/w35l3y/EdgeDrivers/commit/f4827edd743b4cd544199812226755c32ec5cde6 (+ unit tests)
- https://github.com/w35l3y/EdgeDrivers/commit/1c6708f6c48790cae2be812ad668a01c71884836
- https://github.com/w35l3y/EdgeDrivers/commit/013d41ca525106162134223fb2cd826b5bc01918
- https://github.com/w35l3y/EdgeDrivers/commit/cdf8a6f023cd4b54fcc60136f3c9885164bae14f

## Current devices tested with this driver

| Model   | Manufacturer          | Label           | Default profile            | Endpoints                                                  |
| ------- | --------------------- | --------------- | -------------------------- | ---------------------------------------------------------- |
| TS0003  | \_TZ3000_tbfw3xj0     | Multi Switch    | normal-multi-switch-v1     |                                                            |
| TS011F  | \_TZ3000_3zofvcaa     | Multi Switch    | normal-multi-switch-v1     |                                                            |
| TS0001  | \_TZ3210_dse8ogfy_wip | Momentary       | normal-momentary-v3        |   1, 101, 102, 103, 104, 105, 106, 107                     |
| TS0049  | \_TZ3210_0jxeoadc     | Irrigation      | normal-irrigation-v1       | 101, 115, 111                                              |
| TS0601  | \_TZE200_1n2kyphz     | Multi Switch    | normal-multi-switch-v4     |   1,   2,   3,   4                                         |
| TS0601  | \_TZE200_2hf7x9n3     | Multi Switch    | normal-multi-switch-v3     |   1,   2,   3                                              |
| TS0601  | \_TZE200_3i3exuay     | Window Shade    | normal-windowShade-v1      |   1,   2                                                   |
| TS0601  | \_TZE200_3towulqd     | Presence Sensor | normal-presenceSensor-v3   |   1,   4,   9,  10,  12                                    |
| TS0601  | \_TZE200_4hbx5cvx     | Thermostat      | normal-thermostat-v3       |   1,   2,  16,  24, 104, 101                               |
| TS0601  | \_TZE200_8ygsuhe1     | Air Quality     | normal-air-quality-v1      |   2,  18,  19,  21,  22                                    |
| TS0601  | \_TZE200_9mahtqtg     | Multi Switch    | normal-multi-switch-v6     |   1,   2,   3,   4,   5,   6                               |
| TS0601  | \_TZE200_a7sghmms     | Irrigation      | normal-irrigation-v2       |   1,   2, 108, 104                                         |
| TS0601  | \_TZE200_a8sdabtg     | Thermostat      | normal-temphumi-v1         |   1,   2                                                   |
| TS0601  | \_TZE200_akjefhj5     | Irrigation      | normal-irrigation-v1       |   1,   7,  11                                              |
| TS0601  | \_TZE200_amp6tsvy     | Switch          | normal-switch-v1           |   1                                                        |
| TS0601  | \_TZE200_anv5ujhv     | Irrigation      | normal-irrigation-v3       | 102, 108, 110                                              |
| TS0601  | \_TZE200_aoclfnxz     | Thermostat      | normal-thermostat-v2       |  16,  24                                                   |
| TS0601  | \_TZE200_b6wax7g0     | Thermostat      | normal-thermostat-v5       |   2,   3,   1,  14                                         |
| TS0601  | \_TZE200_bcusnqt8     | Power Meter     | normal-powerMeter-v1       |   6,   1                                                   |
| TS0601  | \_TZE200_cxu0jkjk     | Window Shade    | normal-windowShade-v1      |   1,   2,   3,   7                                         |
| TS0601  | \_TZE200_d0ypnbvn     | Smart Valve     | normal-valve-v1            |   1                                                        |
| TS0601  | \_TZE200_dfxkcots     | Dimmer          | normal-single-dimmer-v1    |   1,   2,   3                                              |
| TS0601  | \_TZE200_dwcarsat     | Air Quality     | normal-air-quality-v2      |   2,  18,  19,  20,  21,  22                               |
| TS0601  | \_TZE200_e3oitdyu     | Multi Dimmer    | normal-multi-dimmer-v2     |   1,   2,   3,   4,   7,   8,   9,  10                     |
| TS0601  | \_TZE200_gd4rvykv     | Thermostat      | normal-thermostat-v4       | 101, 103, 102                                              |
| TS0601  | \_TZE200_go3tvswy     | Multi Switch    | normal-multi-switch-v3     |   1,   2,   3                                              |
| TS0601  | \_TZE200_h4cgnbzg     | Thermostat      | normal-thermostat-v4       | 101, 103, 102                                              |
| TS0601  | \_TZE200_ikvncluo     | Presence Sensor | normal-presenceSensor-v1   |   1,   2,   3,   4, 101, 102, 104                          |
| TS0601  | \_TZE200_locansqn     | LCD T+H Sensor  | normal-temphumibatt-v1     |   1,   2,   4                                              |
| TS0601  | \_TZE200_lsanae15     | Power Meter     | normal-powerMeter-v1       |   6,   1                                                   |
| TS0601  | \_TZE200_m9skfctm     | Smoke Detector  | normal-smokeDetector-v1    |   1, 101,  15                                              |
| TS0601  | \_TZE200_mby4kbtq     | Gas Detector    | normal-gasDetector-v1      |   1,  13,  16                                              |
| TS0601  | \_TZE200_mudxchsu     | Thermostat      | normal-thermostat-v5       |  16,  24, 115,  35                                         |
| TS0601  | \_TZE200_myd45weu     | Soil sensor     | normal-temphumibatt-v1     |   5,   3,  15                                              |
| TS0601  | \_TZE200_nklqjk62     | Garage Door     | normal-garage-door-v1      |   1,   3                                                   |
| TS0601  | \_TZE200_nw1r9hp6     | Window Shade    | normal-windowShade-v2      |   1,   2,  13                                              |
| TS0601  | \_TZE200_pay2byax     | Contact Sensor  | normal-contactSensor-v2    |   1, 101,   2                                              |
| TS0601  | \_TZE200_qoy0ekbd     | Thermostat      | normal-temphumi-v1         |   1,   2                                                   |
| TS0601  | \_TZE200_r731zlxk     | Multi Switch    | normal-multi-switch-v6     |   1,   2,   3,   4,   5,   6                               |
| TS0601  | \_TZE200_sh1btabb     | Irrigation      | normal-irrigation-v2       |   1,   2, 108, 104                                         |
| TS0601  | \_TZE200_t1blo2bj     | Alarm           | normal-alarm-v1            |  13,   5,  15,  21,   7                                    |
| TS0601  | \_TZE200_v6ossqfy     | Presence Sensor | normal-presenceSensor-v2   |   1                                                        |
| TS0601  | \_TZE200_ves1ycwx     | Power Meter     | normal-multi-powerMeter-v1 |   6,   1,   7,   8                                         |
| TS0601  | \_TZE200_wfxuhoea     | Garage Door     | normal-garage-door-v1      |   1,   3                                                   |
| TS0601  | \_TZE200_whkgqxse     | LCD T+H Sensor  | normal-temphumibatt-v1     |   1,   2,   4                                              |
| TS0601  | \_TZE200_yjjdcqsq     | Thermostat      | normal-temphumibatt-v1     |   1,   2,   3                                              |
| TS0601  | \_TZE200_yvx5lh6k     | Air Quality     | normal-air-quality-v1      |   2,  18,  19,  21,  22                                    |
| TS0601  | \_TZE200_zl1kmjqx     | LCD T+H Sensor  | normal-temphumibatt-v1     |   1,   2,   4                                              |
| TS0601  | \_TZE200_znbl8dj5     | LCD T+H Sensor  | normal-temphumibatt-v1     |   1,   2,   4                                              |
| TS0601  | \_TZE200_ztc6ggyl     | Presense Sensor | normal-presenceSensor-v1   |   1,   2,   3,   4, 101, 102, 104                          |
| TS0601  | \_TZE204_ac0fhfiq     | Power Meter     | normal-powerMeter-v1       |   6,   1                                                   |
| TS0601  | \_TZE204_cjbofhxw     | Power Meter     | normal-powerMeter-v1       |  18,  19,  20, 101                                         |
| TS0601  | \_TZE204_ntcy3xu1     | Smoke Detector  | normal-smokeDetector-v1    |   1, 101,  14                                              |
| TS0601  | \_TZE204_sbyx0lm6     | Presense Sensor | normal-presenceSensor-v4   |   1,   2,   3,   4, 101, 102, 104, 107, 108, 109, 111, 115 |
| TS0601  | \_TZE204_sxm7l9xa     | Presense Sensor | normal-presenceSensor-v1   | 105, 106, 108, 107, 111, 110, 104                          |
| TS0601  | \_TZE204_t1blo2bj     | Alarm           | normal-alarm-v1            |  13,   5,  15,  21,   7                                    |
| TS0601  | \_TZE204_vqaajp1a     | Smart Valve     | normal-valve-v2            |   1,  20,  21,  22,  23                                    |
| TS0601  | \_TZE204_ztc6ggyl     | Presense Sensor | normal-presenceSensor-v1   |   1,   2,   3,   4, 101, 102, 104                          |
| mcdj3aq | \_TYST11_wmcdj3aq     | Window Shade    | normal-windowShade-v1      |   1,   2,   3,   7                                         |

- This is a list of predefined devices, but the driver is NOT limited to those.<br />It should work with any device that expose EF00 cluster.


## Breaking changes

| Breaking change                      | Affected devices                                                                       | Affects routine | Affects settings | Versions                                                             |
| ------------------------------------ | -------------------------------------------------------------------------------------- | :-------------: | :--------------: | -------------------------------------------------------------------- |
| Conversion of near and far detection | \_TZE200_ikvncluo<br />\_TZE200_ztc6ggyl<br />\_TZE204_sxm7l9xa<br />\_TZE204_ztc6ggyl |       Yes       |       Yes        | B:2023-06-25T20:04:31.169010172<br />M:2023-07-03T18:51:47.174130817 |
| Conversion of illuminance            | \_TZE204_sxm7l9xa                                                                      |       Yes       |        No        | B:2023-06-05T22:36:56.084555341<br />M:2023-06-08T11:48:18.276523603 |


## Known issues

- **Some child devices weren't created**<br />
  Sometimes, when modifying configurations, some child devices aren't created.<br />
  It seems there is a reason to name the function as `driver:try_create_device(...)`<br />
  The driver can't do much about it, but try again.<br />
  Just change datapoint orders to force updating configuration.<br />
  For example, something like "1,2" to "2,1"

  <img src="resources/configuration_3.jpeg" height="300"/>

- **Child dashboard/detail view didn't load properly**<br />
  The driver doesn't know the datapoints until user inform them.<br />
  It will update as soon as it receives data from the device.<br />
  If there are some physical interface with the device (like switches, buttons, sensors, ...), consider triggering it.<br />
  It should make the device send informations to the driver.<br />
  I still don't know how to request data without modifying it as a side effect. Ideas are welcome.

  <img src="resources/child_detailView_1.jpeg" height="300"/>

- **Profile didn't change**<br />
  When modifying profile, it didn't update profile properly.<br />
  Sometimes, it is just cache.<br />
  Return to the dashboard page in the app and go to device detail view. It may require to do more than once or even closing the app.<br />
  It seems there is a reason to name the function as `device:try_update_metadata(...)`<br />
  The driver can't do much about it, but try again.<br />
  You may also change to a random profile and revert it to force updating profile.

  <img src="resources/configuration_4.jpeg" height="300"/>

## Currently untested configurations

- Door Control
- Momentary
- String Tuya Data Type
- Bitmap Tuya Data Type
