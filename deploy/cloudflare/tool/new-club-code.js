// Prints a new club code line for codes.txt, like `klunki relay-code new`:
//   node tool/new-club-code.js "Familie Müller" >> codes.txt
import { newClubCode } from '../src/protocol.js';

const label = process.argv.slice(2).join(' ').replace(/[\r\n#]/g, ' ').trim();
console.log(label === '' ? newClubCode() : `${newClubCode()}  # ${label}`);
