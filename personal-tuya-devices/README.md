## How to use
This driver is intended to work with devices that use 0xEF00 Tuya Cluster

### Install the driver
1. Accept the invitation ( https://api.smartthings.com/invite/6Vjd4YPVJwjN )
2. Enroll the hub
3. List available drivers
4. Install the driver ( Personal Tuya Devices )
### Pair the device
1. Open SmartThings App
2. Search for nearby devices
3. Set the device in pairing mode
### Configure datapoints
1. Open the detail view of the device
2. Open configurations
3. Fill the fields that meets the specified for the device
   * Search the internet about your device details (manufacturer and model)
   * You will find the same device or very similar ones working on other systems (Home Assistant, Hubitat, old Groovy DTHs, ...)
   * Similar devices usually use the same datapoints
   * There are configurations for some stock capabilities<br />
     Currently: switch, switchLevel, contactSensor, doorControl, motionSensor, presenceSensor and waterSensor
   * Also, there are configurations for generic Tuya Data Types<br />
     Currently: Enumeration, value, string, bitmap, raw
   * For example:
     * If you know the datapoint 1 is for a writable boolean, then add it to "Datapoints for switches"
     * If you know the datapoint 2 is for a read-only boolean, then add it to any sensor
### Contribute with your integration
1. Once you know exactly how your device works with each available datapoints, consider adding it to make it a little more user friendly
2. Create or use existing folder with model name at `/src/sub_drivers`<br />
   * If model name folder doesn't exist:<br />
     1. Duplicate `/src/sub_drivers/TEMPLATE` folder and modify all references to the new model name
     2. Add a reference to the new folder at `/src/sub_drivers/model_sub_drivers.lua`
   * If model name folder already exists:<br />
     1. Map the datapoints of the device at `/src/sub_drivers/MODEL/datapoints.lua`
     2. Create a profile that represents the device at `/profiles/normal-XXXXXXXXXXXXXXXXX-vX.yaml`
     3. Add fingerprint that represents the device at `/fingerprints.yaml`


### Known issues
* **Some child devices weren't created**<br />
  Sometimes, when modifying configurations, some child devices aren't created.<br />
  It seems there is a reason to name the function as `driver:try_create_device(...)`<br />
  The driver can't do much about it, but try again.<br />
  Just change datapoint orders to force updating configuration.<br />
  For example, something like "1,2" to "2,1"
* **Child dashboard/detail view didn't load properly**<br />
  The driver doesn't know the datapoints until user inform them.<br />
  It will update as soon as it receives data from the device.<br />
  If there are some physical interface with the device (like switches, buttons, sensors, ...), consider trigger it.<br />
  It should make the device send informations to the driver.

### Currently untested configurations
* Motion Sensor
* Presence Sensor
* Water Sensor
* String Tuya Data Type
* Bitmap Tuya Data Type
* Raw Tuya Data Type
