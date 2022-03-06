import typescript from "@rollup/plugin-typescript";
import embedFile from "./plugins/embed-file";

const bundle = (name) => ({
  input: `src/${name}.ts`,
  output: {
    file: `dist/${name}.js`,
    format: "esm",
  },
  plugins: [embedFile(), typescript({ tsconfig: "./tsconfig.json" })],
});

export default [bundle("openscad.fonts")];
