const fs = require("fs");
const yaml = require("js-yaml");

function update_models(path = ".") {
  const MODEL_FOLDER = path + "/models/";
  const fingerprints = yaml.load(
    fs.readFileSync(path + "/STATIC-fingerprints.yaml", { encoding: "utf-8" })
  );
  const directories = fs.readdirSync(MODEL_FOLDER);
  directories.forEach((directory) => {
    const SPECIFIC_MODEL = directory + "/";
    const files = fs.readdirSync(MODEL_FOLDER + SPECIFIC_MODEL);
    if (!fs.existsSync(path + "/src/models/" + SPECIFIC_MODEL)) {
      fs.mkdirSync(path + "/src/models/" + SPECIFIC_MODEL);
    }
    const manufacturers = [];
    files.forEach((file) => {
      // console.log(file)
      let obj = yaml.load(
        fs.readFileSync(MODEL_FOLDER + SPECIFIC_MODEL + file, {
          encoding: "utf-8",
        })
      );
      let mfr = file.replace(".yaml", "");
      fs.writeFileSync(
        path + "/src/models/" + SPECIFIC_MODEL + mfr + ".lua",
        "return [[" + JSON.stringify(obj) + "]]"
      );
      fingerprints.zigbeeManufacturer.push({
        id: directory + "/" + mfr,
        model: directory,
        manufacturer: mfr,
        deviceProfileName: obj.profiles[0].replace(/_/g, "-"),
        deviceLabel: obj.deviceLabel || "Generic Device",
        zigbeeProfiles: obj.zigbeeProfiles,
        deviceIdentifiers: obj.deviceIdentifiers,
        clusters: obj.clusters,
      });
      // console.log(file, JSON.stringify(obj, null, 2));
      manufacturers.push({
        mfr,
        mdl: directory,
        req: "models." + directory + "." + obj.manufacturer,
      });
    });
    fs.writeFileSync(
      path + "/src/models/" + SPECIFIC_MODEL + "init.lua",
      'local myutils = require "utils"\n\nreturn {\n  ' +
        manufacturers
          .map(
            ({ mfr, mdl }) =>
              '["' +
              mfr +
              '"] = myutils.load_model_from_json("' +
              mdl +
              '", "' +
              mfr +
              '")'
          )
          .join(",\n  ") +
        "\n}"
    );
  });
  let maxLength = fingerprints.zigbeeManufacturer.reduce(
    (acc, { model, manufacturer, deviceLabel, deviceProfileName }) => {
      const t = [
        model,
        manufacturer.replace(/^_/, "\\_"),
        deviceLabel,
        deviceProfileName,
      ];
      return acc.map((v, i) => Math.max(v, t[i].length));
    },
    [0, 0, 0, 0]
  );

  fs.writeFileSync(
    path + "/DEVICES.md",
    [
      "",
      "Model".padEnd(maxLength[0], " "),
      "Manufacturer".padEnd(maxLength[1], " "),
      "Label".padEnd(maxLength[2], " "),
      "Default profile".padEnd(maxLength[3], " "),
      "",
    ]
      .join(" | ")
      .trim() +
      "\n" +
      [
        "",
        "".padEnd(maxLength[0], "-"),
        "".padEnd(maxLength[1], "-"),
        "".padEnd(maxLength[2], "-"),
        "".padEnd(maxLength[3], "-"),
        "",
      ]
        .join(" | ")
        .trim() +
      "\n" +
      fingerprints.zigbeeManufacturer
        .map(({ model, manufacturer, deviceLabel, deviceProfileName }) =>
          [
            "",
            model.padEnd(maxLength[0], " "),
            manufacturer.replace(/^_/, "\\_").padEnd(maxLength[1], " "),
            deviceLabel.padEnd(maxLength[2], " "),
            deviceProfileName.padEnd(maxLength[3], " "),
            "",
          ]
            .join(" | ")
            .trim()
        )
        .join("\n") +
      "\n\n- This is a list of predefined devices, but the driver is NOT limited to those.<br />It should work with any device that expose EF00 cluster.\n"
  );
  fs.writeFileSync(
    path + "/src/models/init.lua",
    "return {\n  " +
      directories
        .map((mdl) => '["' + mdl + '"] = require "models.' + mdl + '"')
        .join(",\n  ") +
      "\n}"
  );
  fs.writeFileSync(
    path + "/fingerprints.yaml",
    yaml.dump(fingerprints, {
      styles: {
        "!!int": "hexadecimal",
      },
    })
  );
}

module.exports = {
  update_models,
};
