import { OpenSCAD } from "./openscad";
import { fromHex } from "./files";

import config from "../../res/fonts/fonts.conf";
import fonts from "../../res/liberation";

export function addFonts(openscad: OpenSCAD) {
  openscad.FS.mkdir("/fonts");
  openscad.FS.writeFile("/fonts/fonts.conf", fromHex(config as string));
  for (const [file, data] of Object.entries(fonts as Record<string, string>)) {
    openscad.FS.writeFile("/fonts/" + file, fromHex(data));
  }
}
