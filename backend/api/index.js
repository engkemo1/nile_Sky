// Vercel serverless entry.
//
// Plain JavaScript on purpose: Vercel compiles files in api/ with esbuild,
// which does not emit decorator metadata — that would break Nest's DI.
// So the TypeScript is compiled ahead of time by `nest build` (see
// buildCommand in vercel.json) and this file only forwards to the result.
module.exports = require('../dist/serverless').default;
