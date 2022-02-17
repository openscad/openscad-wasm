import { assertEquals } from "https://deno.land/std@0.125.0/testing/asserts.ts";
import OpenScad from "../build/openscad.js";

for await (const entry of Deno.readDir(".")) {
  if (!entry.isDirectory) {
    continue;
  }

  Deno.test({
    name: entry.name,
    fn: () => runTest(entry.name),
  });
}

async function runTest(directory: string) {

  const instance = await OpenScad({ noInitialRun: true });

  await loadTestFiles(instance, directory);
  
  const code = instance.callMain([`/test.scad`, "-o", "out.stl"]);
  assertEquals(0, code);

  const output = instance.FS.readFile("out.stl");
  await Deno.writeFile(`${directory}/out.stl`, output);
}

async function loadTestFiles(instance: any, directory: string) {
  for await (const testFile of Deno.readDir(directory)) {
    const content = await Deno.readFile(`${directory}/${testFile.name}`);
    instance.FS.writeFile(`/${testFile.name}`, content);
  }
}
