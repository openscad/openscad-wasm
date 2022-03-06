import { OpenSCAD } from "./openscad";
import config from "../../res/fonts/fonts.conf";
import fonts from "../../res/liberation";

export function addFonts(openscad: OpenSCAD) {
  openscad.FS.mkdir("/fonts");
  openscad.FS.writeFile("/fonts/fonts.conf", fromHex(config as string));
  for (const [file, data] of Object.entries(fonts as Record<string, string>)) {
    openscad.FS.writeFile("/fonts/" + file, fromHex(data));
  }
}

function fromHex(hex: string): Uint8Array {
  return new Uint8Array(hex.match(/../g)!.map(h=>parseInt(h,16)))
}
