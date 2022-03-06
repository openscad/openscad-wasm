import typescript from '@rollup/plugin-typescript';
import embedFile from "./plugins/embed-file";

export default {
  input: "src/openscad.runtime.ts",
  output: {
    file: "dist/openscad.runtime.js",
    format: "esm",
  },

  plugins: [
    embedFile(),
    typescript({ tsconfig: './tsconfig.json' }),
  ]
};
