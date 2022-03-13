import { OpenSCAD } from "./openscad";
import { fromHex } from "./files";

import mcad from "../../res/MCAD";

export function addMCAD(openscad: OpenSCAD) {
  openscad.FS.mkdir("/libraries");
  openscad.FS.mkdir("/libraries/MCAD");

  for (const [file, data] of Object.entries(mcad as Record<string, string>)) {
    openscad.FS.writeFile("/libraries/MCAD/" + file, fromHex(data));
  }
}
