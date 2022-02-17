import { Application } from "https://deno.land/x/oak/mod.ts";
import logger from "https://deno.land/x/oak_logger/mod.ts";
import { join } from "https://deno.land/std/path/mod.ts";

const app = new Application();

app.use(logger.logger);

// Enable CORP headers for SharedArrayBuffer
app.use(async (context, next) => {
    context.response.headers.append("Cross-Origin-Opener-Policy", "same-origin");
    context.response.headers.append("Cross-Origin-Embedder-Policy", "require-corp");
    await next();
})

// Serve static files from example/www and build folders
app.use(async (context, next) => {
  try {
    await context.send({ root: join(Deno.cwd(), "www") });
  } catch {
    try {
      await context.send({ root: join(Deno.cwd(), "../build") });
    } catch {
      await next();
    }
  }
});

const port = 8080;
console.log(`server listening on port ${port}...`);
await app.listen({ port });
