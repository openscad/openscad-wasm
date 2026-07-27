import { assertEquals } from "https://deno.land/std@0.125.0/testing/asserts.ts";

Deno.test({
  name: "Test event loop resolution",
  fn: async () => {
      // Simulate Deno.test issue where promise is left pending
      const p = new Promise(resolve => setTimeout(resolve, 5000));
      // not awaiting p
  },
});
