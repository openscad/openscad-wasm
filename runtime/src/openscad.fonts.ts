import { OpenSCAD } from "./openscad";
import { writeFile, writeFolder } from "./files";

import config from "../../res/fonts/fonts.conf";
import fonts from "../../res/liberation";

export function addFonts(openscad: OpenSCAD) {
  writeFile(openscad.FS, "/fonts/fonts.conf", config as string);
  writeFolder(openscad.FS, "/fonts/", fonts as Record<string, string>);
}
