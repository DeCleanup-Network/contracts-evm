import chai from "chai";
import { setupErrorMatchers } from "./errorMessages";

// Setup custom error matchers for tests
setupErrorMatchers(chai as any);

export { chai };
export const { expect } = chai;

declare global {
  namespace Chai {
    interface Assertion {
      rejectedWith(expected: string): Promise<void>;
    }
  }
}

declare module "chai" {
  interface ChaiStatic {
    AssertionError: any;
    version: string;
  }
}
