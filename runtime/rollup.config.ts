import typescript from '@rollup/plugin-typescript';

export default {
  input: "src/openscad.runtime.ts",
  output: {
    file: "dist/openscad.runtime.js",
    format: "esm",
  },
  plugins: [typescript({ tsconfig: './tsconfig.json' })]
};
