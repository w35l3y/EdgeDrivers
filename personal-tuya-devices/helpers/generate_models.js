const fs = require("fs");
const yaml = require("js-yaml");

const MODEL_FOLDER = "../models/";
fs.readdir(MODEL_FOLDER, (err, files) => {
  files.forEach((file) => {
    obj = yaml.load(
      fs.readFileSync(MODEL_FOLDER + file, { encoding: "utf-8" })
    );
    fs.writeFileSync(
      "../src/models/" + file.replace(".yaml", ".lua"),
      "return [[" + JSON.stringify(obj) + "]]"
    );
  });
});
