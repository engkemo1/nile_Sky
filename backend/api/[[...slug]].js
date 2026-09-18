// Vercel serverless entry (catch-all).
//
// Plain JavaScript on purpose: Vercel compiles files in api/ with esbuild,
// which does not emit decorator metadata — that would break Nest's DI.
// The TypeScript is compiled ahead of time by `nest build` (see buildCommand
// in vercel.json) and this file only forwards to the result.
//
// The [[...slug]] name makes this a catch-all, so /api/weather/luxor lands
// here instead of 404ing. vercel.json rewrites /(.*) to /api/$1, and the
// handler strips the /api prefix before Nest routes the request.
module.exports = require('../dist/serverless').default;
