export interface InitOptions {
  noInitialRun: boolean;
}

export interface OpenSCAD {
  callMain(args: Array<string>): number;
  FS: FS;
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

// deno-lint-ignore no-unused-vars
export default function (init: InitOptions): Promise<OpenSCAD> {
  // NULL implementation. Will be replaced by the actual OpenSCAD library
  return null as unknown as Promise<OpenSCAD>;
}
