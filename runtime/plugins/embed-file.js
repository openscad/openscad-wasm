import { resolve } from "path";
import { readFileSync, statSync } from "fs";
import { join } from "path";
import { promisify } from "util";
import glob from "glob";

export default function embedFile() {
  function loadFile(path) {
    const content = readFileSync(path);
    return `export default "${content.toString("hex")}";`;
  }

  async function loadFolder(path) {
    const files = {};

    const res = await promisify(glob)("**/*", { cwd: resolve(path), nodir: true });
    for (const file of res) {
      files[file] = readFileSync(join(path, file)).toString("hex");
    }

    return `export default ${JSON.stringify(files)};`;
  }

  return {
    name: "embed-file",
    resolveId(source) {
      const id = resolve("./src", source);
      if (id.startsWith(resolve("../res"))) {
        return id;
      }
    },
    load(id) {
      if (id.startsWith(resolve("../res"))) {
        return "";
      }
    },
    transform(_, id) {
      if (id.startsWith(resolve("../res"))) {
        if (statSync(id).isFile()) {
          return loadFile(id);
        } else {
          return loadFolder(id);
        }
      }
    },
  };
}
