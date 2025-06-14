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

# Build the project in debug mode
make ENV=Debug build
```

## MacOS

On MacOS, the version of Make that ships with the OS (3.81) is not compatible with this makefile, so you'll need to install a modern version of make and use that instead.

For instance, with homebrew:

`brew install gmake`

Depending on your PATH configuration, you may need to use `gmake` instead of `make` when running setup commands.

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
<html>
<head></head>
<body>

<script type="module">

import OpenSCAD from "./openscad.js";

// OPTIONAL: add fonts to the FS
import { addFonts } from "./openscad.fonts.js";

// OPTIONAL: add MCAD library to the FS
import { addMCAD } from "./openscad.mcad.js";

const filename = "cube.stl";

// Instantiate the application
const instance = await OpenSCAD({noInitialRun: true});

// Write a file to the filesystem
instance.FS.writeFile("/input.scad", `cube(10);`); // OpenSCAD script to generate a 10mm cube

// Run like a command-line program with arguments
instance.callMain(["/input.scad", "--enable=manifold", "-o", filename]); // manifold is faster at rendering

// Read the output 3D-model into a JS byte-array
const output = instance.FS.readFile("/"+filename);

// Generate a link to output 3D-model and download the output STL file
const link = document.createElement("a");
link.href = URL.createObjectURL(
new Blob([output], { type: "application/octet-stream" }), null);
link.download = filename;
document.body.append(link);
link.click();
link.remove();

</script>

</body>
</html>
```

For more information on reading and writing files check out the [Emscripten File System API](https://emscripten.org/docs/api_reference/Filesystem-API.html).
