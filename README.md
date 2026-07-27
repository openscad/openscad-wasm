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

## Windows Build

For Windows users (or anyone preferring to skip `make`), you can build the project using the native Podman or Docker CLI and the provided PowerShell script. Make sure you have Podman Desktop or Docker Desktop, and Node/npm installed.

Run the build script from PowerShell:

```powershell
.\build.ps1
```

This script will run a multi-stage process that fetches dependencies, builds the Emscripten toolchain, compiles the project, and extracts the WASM files to the `build/` directory using standard container commands (no `compose` required).

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

## Installation

To use `openscad-wasm` in another local project, you can install it directly from your local filesystem using NPM.

First, ensure you have built the project (`make build` or `.\build.ps1`). Then, in your other project, run:

```bash
npm install file:../path/to/openscad-wasm
```

## API

The project is an ES6 module. Once installed, simply import the module into your application:

```javascript
import OpenSCAD from "openscad-wasm";

// OPTIONAL: add fonts to the FS
import { addFonts } from "openscad-wasm/build/openscad.fonts.js";

// OPTIONAL: add MCAD library to the FS
import { addMCAD } from "openscad-wasm/build/openscad.mcad.js";

const filename = "cube.stl";

// Instantiate the application
const instance = await OpenSCAD({noInitialRun: true});
```

### Example Usage in a Browser:

```html
<html>
<head></head>
<body>

<script type="module">

import OpenSCAD from "./build/openscad.js";

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
