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

const { base64utf8, fragmentSource, escapeHtml, removeANSIEscapeCodes } = require("../copacabana/cmake/asset/godbolt.js");

// Node's Buffer is an independent implementation of the same encoding, so it answers what the
// expected string is without restating how the asset computes it.
const expected = (str) => Buffer.from(str, "utf8").toString("base64");

test("base64utf8 agrees with Buffer on plain ASCII", () => {
  assert.equal(base64utf8(""), expected(""));
  assert.equal(base64utf8("lib::pi"), expected("lib::pi"));
});

test("base64utf8 encodes the characters btoa alone refuses", () => {
  // Two bytes, three bytes, and a surrogate pair, which is where a naive charCodeAt loop breaks.
  for (const str of ["lib::π", "lib::γ", "lib::ω", "日本語", "🎉"]) {
    assert.equal(base64utf8(str), expected(str));
    assert.throws(() => btoa(str), { name: "InvalidCharacterError" });
  }
});

test("a clientstate payload survives the round trip", () => {
  const data = { sessions: [{ id: 1, language: "c++", source: "auto x = lib::π;" }] };
  const state = base64utf8(JSON.stringify(data));

  assert.deepEqual(JSON.parse(Buffer.from(state, "base64").toString("utf8")), data);
});

// A doxygen fragment, reduced to the three things fragmentSource asks of it. The nodes it drops are the ones a real
// page carries for the line numbers and the tooltips, and they report having been removed.
const fragment = (text, junk = []) => {
  const node = {
    textContent: text,
    cloneNode: () => node,
    querySelectorAll(selector) {
      node.asked = selector;
      return junk;
    },
  };

  return node;
};

test("fragmentSource drops the newlines doxygen leaves at the end", () => {
  assert.equal(fragmentSource(fragment("int main() {}\n\n\n")), "int main() {}");
  assert.equal(fragmentSource(fragment("int main() {}")), "int main() {}");
  assert.equal(fragmentSource(fragment("\n\n")), "");
});

test("fragmentSource keeps the newlines inside the source", () => {
  assert.equal(fragmentSource(fragment("int main()\n{\n}\n")), "int main()\n{\n}");
});

test("fragmentSource removes the line numbers and the tooltips", () => {
  let removed = 0;
  const junk = [{ remove: () => ++removed }, { remove: () => ++removed }];
  const node = fragment("code", junk);

  fragmentSource(node);

  assert.equal(node.asked, ".lineno, .ttc");
  assert.equal(removed, 2);
});

test("escapeHtml turns a compiler's output into something a page can hold", () => {
  assert.equal(escapeHtml("<int&> \"x\" 'y'"), "&lt;int&amp;&gt; &quot;x&quot; &#39;y&#39;");
});

test("removeANSIEscapeCodes strips the colours a compiler adds", () => {
  assert.equal(removeANSIEscapeCodes("\u001b[31merror\u001b[0m: no"), "error: no");
  assert.equal(removeANSIEscapeCodes("plain"), "plain");
});
