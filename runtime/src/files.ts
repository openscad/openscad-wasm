export function fromHex(hex: string): Uint8Array {
  return new Uint8Array(hex.match(/../g)!.map((h) => parseInt(h, 16)));
}
