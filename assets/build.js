const esbuild = require("esbuild");

const args = process.argv.slice(2);
const watch = args.includes('--watch');
const deploy = args.includes('--deploy');

const { sassPlugin } = require("esbuild-sass-plugin");

const isProd = process.argv[2] === 'prod'

const loader = {
  // Add loaders for images/fonts/etc, e.g. { '.svg': 'file' }
};

const plugins = [
  // Add and configure plugins here
  sassPlugin({
    cache: true
  })
];

// Define esbuild options
let opts = {
  entryPoints: ["js/app.js"],
  bundle: true,
  logLevel: "info",
  target: "es2022",
  outdir: "../priv/static/assets",
  external: ['*.woff2','*.woff', '*.ttf', '*.otf'],
  loader,
  plugins,
  minify: !!isProd,
};

if (deploy) {
  opts = {
    ...opts,
    minify: true,
  };
}

if (watch) {
  opts = {
    ...opts,
    sourcemap: "inline",
  };
  esbuild
    .context(opts)
    .then((ctx) => {
      ctx.watch();
    })
    .catch((_error) => {
      process.exit(1);
    });
} else {
  esbuild.build(opts);
}