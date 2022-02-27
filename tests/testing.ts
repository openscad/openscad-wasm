export async function loadTestFiles(instance: any, directory: string) {
  for await (const testFile of Deno.readDir(directory)) {
    const content = await Deno.readFile(`${directory}/${testFile.name}`);
    instance.FS.writeFile(`/${testFile.name}`, content);
  }
}
