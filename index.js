const { update_models_zigbee } = require("./helpers");

update_models_zigbee("personal-tuya-devices");
// update_models_lan("event-stream", ({ service_type, domain }) =>
//   [...service_type.split("."), domain].join("/")
// );
