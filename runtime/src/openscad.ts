export interface InitOptions {
  noInitialRun: boolean;
  print?: (text: string) => void;
  printErr?: (text: string) => void;
}

export interface OpenSCAD {
  callMain(args: Array<string>): number;
  FS: FS;
  locateFile?: (path: string, prefix: string) => string;
  onRuntimeInitialized?: () => void;
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

  globalThis.OpenSCAD = module;
  await import(wasmModule + `#${Math.random()}`);
  delete globalThis.OpenSCAD;

  await new Promise((resolve) => {
    module.onRuntimeInitialized = () => resolve(null);
  });

  return module as unknown as OpenSCAD;
}

export default OpenSCAD;
