// Entry point of the Klunki relay Worker (KLD-114): the request handler and
// the Durable Object class (one per room). Only these two may be exported
// here: the runtime treats every named export as an entry point.
import { createRelay } from './relay.js';

export { RelayRoom } from './room.js';

export default createRelay();
