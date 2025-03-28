import chai from "chai";
import { setupErrorMatchers } from "./errorMessages";

// Setup custom error matchers for tests
setupErrorMatchers(chai);

export { chai };
export const { expect } = chai;
