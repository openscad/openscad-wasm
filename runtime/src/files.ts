import { FS } from "./openscad";

export function writeFile(
  fs: FS,
  filePath: string,
  contents: string,
) {
  ensureDirectoryExists(fs, filePath);
  fs.writeFile(filePath, fromHex(contents));
}

export function writeFolder(
  fs: FS,
  base: string,
  contents: Record<string, string>,
) {
  for (const [file, data] of Object.entries(contents)) {
    const fullPath = base + file;
    ensureDirectoryExists(fs, fullPath);
    fs.writeFile(fullPath, fromHex(data));
  }
}

function fromHex(hex: string): Uint8Array {
  if (hex.length == 0) {
    return new Uint8Array(0);
  }
  return new Uint8Array(hex.match(/../g)!.map((h) => parseInt(h, 16)));
}

function ensureDirectoryExists(fs: FS, filePath: string) {
  const dirIndex = filePath.lastIndexOf("/");
  if (dirIndex != -1) {
    const dirname = filePath.substring(0, dirIndex);
    ensureDirectoryExists(fs, dirname);
    if (dirname != "" && !exists(fs, dirname)) {
      fs.mkdir(dirname);
    }
  }
}

function exists(fs: FS, path: string) {
  try {
    fs.stat(path);
    return true;
  } catch (e) {
    return false;
  }
}
