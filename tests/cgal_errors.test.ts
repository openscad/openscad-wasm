import { assertEquals, assertNotEquals } from "https://deno.land/std@0.125.0/testing/asserts.ts";
import OpenScad from "../build/openscad.js";

Deno.test({
  name: "CGAL Error: precondition violation with twisted linear_extrude",
  fn: async () => {
    let stderr = "";

    const instance = await OpenScad({
        noInitialRun: true,
        printErr: (text: string) => {
            stderr += text + "\n";
        },
        locateFile: (path: string) => { return new URL('../build/' + path, import.meta.url).href; },
        wasmBinary: Deno.readFileSync(new URL("../build/openscad.wasm", import.meta.url)),
    });

    // A minimal self-contained reproduction of single_cell_filter / flat_end_screw
    // using linear_extrude with a high twist and boolean operations
    // This previously generated "Expr: dimension() < 2" or "ERROR: The given mesh is not closed!"
    const scadContent = `
    $fn = 60;
    intersection() {
        difference() {
            linear_extrude(height = 20, twist = 720) {
                translate([5, 0]) circle(r = 2);
            }
            linear_extrude(height = 20, twist = 720) {
                translate([5, 0]) square([2, 4], center=true);
            }
        }
        cylinder(r = 10, h = 20, center = true);
    }
    `;

    instance.FS.writeFile("/test.scad", scadContent);

    const code = instance.callMain(["/test.scad", "-o", "out.stl"]);

    // We assert that the code runs successfully and doesn't throw CGAL errors
    assertEquals(code, 0, "Expected success code 0, but got an error code");

    // Ensure the specific CGAL errors are no longer present in the output
    const hasPreconditionViolation = stderr.includes("Expr: dimension() < 2");
    const hasMeshUnclosedError = stderr.includes("ERROR: The given mesh is not closed!");

    assertEquals(hasPreconditionViolation, false, "Still encountered CGAL precondition violation");
    assertEquals(hasMeshUnclosedError, false, "Still encountered unclosed mesh error");
  },
});
