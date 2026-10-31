import { message } from "../acp/errors.js"
export * as AgyError from "./agy-error.js"
export function readable(error: unknown): Error {
  return new Error(message(error), { cause: error })
}
