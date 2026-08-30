//==================================================================================================
//  Copacabana - Common CMake Package Tools
//  Copyright : Copacabana Project Contributors
//  SPDX-License-Identifier: BSL-1.0
//==================================================================================================
// The asset is a classic browser script, so it is loaded here against the smallest DOM that lets
// it reach its last line. What is exercised afterwards are the pure helpers it exports.
const test = require("node:test");
const assert = require("node:assert/strict");

global.HTMLElement = class {};
global.document = { createElement: () => ({}), head: { appendChild() {} } };
global.customElements = { define() {} };

const { base64utf8 } = require("../copacabana/cmake/asset/godbolt.js");

// Node's Buffer is an independent implementation of the same encoding, so it answers what the
// expected string is without restating how the asset computes it.
const expected = (str) => Buffer.from(str, "utf8").toString("base64");

test("base64utf8 agrees with Buffer on plain ASCII", () => {
  assert.equal(base64utf8(""), expected(""));
  assert.equal(base64utf8("eve::pi"), expected("eve::pi"));
});

test("base64utf8 encodes the characters btoa alone refuses", () => {
  // Two bytes, three bytes, and a surrogate pair, which is where a naive charCodeAt loop breaks.
  for (const str of ["eve::π", "eve::γ", "eve::ω", "日本語", "🎉"]) {
    assert.equal(base64utf8(str), expected(str));
    assert.throws(() => btoa(str), { name: "InvalidCharacterError" });
  }
});

test("a clientstate payload survives the round trip", () => {
  const data = { sessions: [{ id: 1, language: "c++", source: "auto x = eve::π;" }] };
  const state = base64utf8(JSON.stringify(data));

  assert.deepEqual(JSON.parse(Buffer.from(state, "base64").toString("utf8")), data);
});
