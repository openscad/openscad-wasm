# OpenSCAD WASM Port

A full port of OpenSCAD to WASM. 

This project cross compiles all of the project dependencies and created a headless OpenSCAD WASM module.

## Setup

Make sure that you have the following installed:

- Make
- Docker
- Deno
- lzip (might be missing on some distros)

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
<head>
<script src="./openscad.js" type="module"></script>
</head>
<body>

<script type="module">

import OpenSCAD from "./openscad.js";
// OPTIONAL: add fonts to the FS
import { addFonts } from "./openscad.fonts.js";
// OPTIONAL: add MCAD library to the FS
import { addMCAD } from "./openscad.mcad.js";

let filename = "cube.stl";
const instance = await OpenSCAD({noInitialRun: true});
instance.FS.writeFile("/input.scad", `cube(10);`);
instance.callMain(["/input.scad", "--enable=manifold", "-o", filename]);
const output = instance.FS.readFile("/"+filename);

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
