import { assertEquals, assertStringIncludes, assertNotEquals } from "https://deno.land/std@0.125.0/testing/asserts.ts";
import { join } from "https://deno.land/std/path/mod.ts";
import { loadTestFiles } from "./testing.ts";

import OpenScad, { OpenSCAD } from "../build/openscad.js";
import { addFonts } from "../build/openscad.fonts.js";
import { addMCAD } from "../build/openscad.mcad.js";

Deno.test("csg", async () => {
  const instance = await OpenScad({ noInitialRun: true });
  await runTest(instance, "./csg");
});

Deno.test("cube", async () => {
  const instance = await OpenScad({ noInitialRun: true });
  await runTest(instance, "./cube");
});

Deno.test("cylinder", async () => {
  const instance = await OpenScad({ noInitialRun: true });
  await runTest(instance, "./cylinder");
});

Deno.test("lib", async () => {
  const instance = await OpenScad({ noInitialRun: true });
  await runTest(instance, "./lib");
});

Deno.test("mcad", async () => {
  const instance = await OpenScad({ noInitialRun: true });
  addMCAD(instance);
  await runTest(instance, "./mcad");
});

Deno.test("text", async () => {
  const instance = await OpenScad({ noInitialRun: true });
  addFonts(instance);
  await runTest(instance, "./text");
});

Deno.test("print stderr", async () => {
  let stderr = "";

  const instance = await OpenScad({ 
    noInitialRun: true,
    printErr: (text) => stderr += text + "\n",
   });
  await runTest(instance, "./cube");

  assertStringIncludes(stderr, "Facets:");
});

Deno.test("print stdout", async () => {
  let stdout = "";

  const instance = await OpenScad({ 
    noInitialRun: true,
    print: (text) => stdout += text + "\n",
   });
  await runTest(instance, "./cube", "-");

  assertNotEquals(stdout.length, 0);
});

async function runTest(instance: OpenSCAD, directory: string, outfile?: string) {
  const __dirname = new URL('.', import.meta.url).pathname;

  await loadTestFiles(instance, join(__dirname, directory));
  
  const code = instance.callMain([`/test.scad`, "--export-format", "stl", "-o", outfile ?? "out.stl"]);
  assertEquals(0, code);

  const output = instance.FS.readFile("out.stl", { encoding: "binary" });
  await Deno.writeFile(join(__dirname, directory, "out.stl"), output);
}
