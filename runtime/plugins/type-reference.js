import { resolve } from "path";

export default function typeReference(file, name) {
  return {
    name: "type-reference",
    transform(code, id) {
      if (resolve(id) == resolve(file)) {
        return `/// <reference types="./${name}.d.ts" />\n${code}`;
      }
    },
  };
}
