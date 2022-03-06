import { OpenSCAD } from "./openscad";
import config from "../../res/fonts/fonts.conf";
import fonts from "../../res/liberation";

export function addFonts(openscad: OpenSCAD) {
  openscad.FS.mkdir("/fonts");
  openscad.FS.writeFile("/fonts/fonts.conf", new Uint8Array(config as number[]));
  for (const [file, data] of Object.entries(fonts as Record<string, number[]>)) {
    openscad.FS.writeFile("/fonts/" + file, new Uint8Array(data));
  }
}
