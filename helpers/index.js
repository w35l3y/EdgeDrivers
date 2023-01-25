const fs = require("fs");
const yaml = require("js-yaml");

function update_models(path = ".") {
  const MODEL_FOLDER = path + "/models/";
  fs.readdir(MODEL_FOLDER, (err, files) => {
    files.forEach((file) => {
      obj = yaml.load(
        fs.readFileSync(MODEL_FOLDER + file, { encoding: "utf-8" })
      );
      fs.writeFileSync(
        path + "/src/models/" + file.replace(".yaml", ".lua"),
        "return [[" + JSON.stringify(obj) + "]]"
      );
    });
  });
}

module.exports = {
  update_models
};