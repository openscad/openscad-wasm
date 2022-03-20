import typescript from "@rollup/plugin-typescript";
import embedFile from "./plugins/embed-file";
import typeReference from "./plugins/type-reference";

const bundle = (name) => ({
  input: `src/${name}.ts`,
  output: {
    file: `dist/${name}.js`,
    format: "esm",
  },
  plugins: [
    embedFile(), 
    typescript({ tsconfig: "./tsconfig.json" }),
    typeReference(`src/${name}.ts`, name),
  ]
});

export default [
  bundle("openscad"),
  bundle("openscad.fonts"),
  bundle("openscad.mcad")
];
