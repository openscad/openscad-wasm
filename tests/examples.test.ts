import { assertEquals } from "https://deno.land/std@0.125.0/testing/asserts.ts";
import OpenScad from "../build/openscad.js";
import { addFonts } from "../build/openscad.fonts.js";
import { join } from "https://deno.land/std/path/mod.ts";
import { loadTestFiles } from "./testing.ts";

const exampleDir = "../libs/openscad/examples/";
const sets = [
  "Basics",
  "Advanced",
  "Parametric",
];

const examples = JSON.parse(
  await Deno.readTextFile(join(exampleDir, "examples.json")),
);

for (const set of sets) {
  for (const file of examples[set]) {
    Deno.test({
      name: `${set}: ${file}`,
      fn: () => runTest(file, join(exampleDir, set)),
    });
  }
}

async function runTest(entrypoint: string, directory: string) {
  const instance = await OpenScad({ noInitialRun: true });
  addFonts(instance);

  await loadTestFiles(instance, directory);

  const code = instance.callMain([entrypoint, "-o", "out.stl"]);
  assertEquals(0, code);
}
