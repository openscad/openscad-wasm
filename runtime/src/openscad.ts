export interface InitOptions {
  noInitialRun?: boolean;
  print?: (text: string) => void;
  printErr?: (text: string) => void;
  locateFile?: (path: string, prefix?: string) => string;
  wasmBinary?: Uint8Array;
  onRuntimeInitialized?: () => void;
  onAbort?: (what: any) => void;
}

export interface OpenSCAD {
  callMain(args: Array<string>): number;
  FS: FS;
  locateFile?: (path: string, prefix?: string) => string;
  wasmBinary?: Uint8Array;
  onRuntimeInitialized?: () => void;
  onAbort?: (what: any) => void;
}

export interface FS {
  mkdir(path: string): void;
  rename(oldpath: string, newpath: string): void;
  rmdir(path: string): void;
  stat(path: string): unknown; //TODO: add stat result obj
  readFile(path: string): string | Uint8Array;
  readFile(path: string, opts: { encoding: "utf8" }): string;
  readFile(path: string, opts: { encoding: "binary" }): Uint8Array;
  writeFile(path: string, data: string | ArrayBufferView): void;
  unlink(path: string): void;
}

declare module globalThis {
  let OpenSCAD: Partial<OpenSCAD> | undefined;
  let Module: Partial<OpenSCAD> | undefined;
}

let wasmModule: string;

async function OpenSCAD(options?: InitOptions): Promise<OpenSCAD> {
  if (!wasmModule) {
    const url = new URL(`./openscad.wasm.js`, import.meta.url).href;
    const request = await fetch(url);
    wasmModule = "data:text/javascript;base64," + btoa(await request.text());
  }

  const module: Partial<OpenSCAD> = {
    noInitialRun: true,
    locateFile: (path: string) => new URL(`./${path}`, import.meta.url).href,
    ...options,
  };

  const initPromise = new Promise((resolve, reject) => {
    const originalOnRuntimeInitialized = module.onRuntimeInitialized;
    module.onRuntimeInitialized = () => {
      if (originalOnRuntimeInitialized) originalOnRuntimeInitialized();
      resolve(null);
    };

    const originalOnAbort = module.onAbort;
    module.onAbort = (what: any) => {
      if (originalOnAbort) originalOnAbort(what);
      reject(new Error("Emscripten aborted: " + String(what)));
    };
  });

  // Emscripten might default to looking for 'Module' if 'EXPORT_NAME' isn't explicitly set in CMake
  globalThis.OpenSCAD = module;
  globalThis.Module = module;

  try {
    const namespace = await import(wasmModule + `#${Math.random()}`);

    // Grab the factory function. It will either be the ES6 default export or attached to the globals
    const factory = namespace.default || globalThis.OpenSCAD || globalThis.Module;

    if (typeof factory === 'function') {
      // Execute the factory function to actually start Emscripten initialization
      const instance = factory(module);

      // If the factory returns a promise (common in newer Emscripten), wait for it
      if (instance instanceof Promise) {
        await instance;
      }
    }
  } catch (e) {
    throw e;
  } finally {
    // Clean up globals
    delete globalThis.OpenSCAD;
    delete globalThis.Module;
  }

  // Wait for the specific Emscripten runtime ready event
  await initPromise;

  return module as unknown as OpenSCAD;
}

export default OpenSCAD;
