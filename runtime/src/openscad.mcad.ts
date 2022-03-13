import { OpenSCAD } from "./openscad";
import { writeFolder } from "./files";

import mcad from "../../res/MCAD";

export function addMCAD(openscad: OpenSCAD) {
  writeFolder(openscad.FS, "/libraries/MCAD/", mcad as Record<string, string>);
}
