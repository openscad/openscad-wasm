# OpenSCAD WASM Port

A full port of OpenSCAD to WASM. 

This project cross compiles all of the project dependencies and created a headless OpenSCAD WASM module.

## Setup
Make sure that you have the following installed:
- Make
- Docker
- Deno

To build the project:

```
make all
```

Or for specific steps:

```
# Generate the library files
make libs 

# Build the project
make build
```

## Usage

There is an example project in the example folder. Run it using:

```
cd example
deno run --allow-net --allow-read server.ts

# or

make example
```

There are also automated tests that can be run using:

```
cd tests
deno test --allow-read --allow-write

# or

make test
```

## API

The project is an ES6 module. Simply import the module:

```ts
import OpenSCAD from "./openscad.js";

// Instantiate the application
const instance = await OpenSCAD({ noInitialRun: true });

// Write a file to the filesystem
instance.FS.writeFile("/input.scad", `cube(10);`);

// Run OpenSCAD with the arguments "/input.scad -o cube.stl"
instance.callMain(["/input.scad", "-o", "cube.stl"]);

// Read the data from cube.stl
const output = instance.FS.readFile("/cube.stl");
```

For more information on reading and writing files check out the [Emscripten File System API](https://emscripten.org/docs/api_reference/Filesystem-API.html).

## Project Status
- [x] module builds
- [x] module runs
- [ ] library created
- [ ] tests exist

## Future work
- [ ] Fix NULLGL in OpenSCAD 2021
- [ ] Merge WASM patch into Boost.Filesystem

## Known Issues
- [ ] text does not render
    Fonts appear to be missing but FontConfig seems to be working correctly. This seems to just be a config issue at runtime.
- [ ] CGAL error on intersection between cube and circle (might be a 2019 issue)
