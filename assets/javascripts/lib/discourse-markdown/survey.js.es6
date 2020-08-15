/*eslint no-bitwise:0 */
import I18n from "I18n";

const DATA_PREFIX = "data-survey-";
const DEFAULT_SURVEY_NAME = "survey";
const WHITELISTED_ATTRIBUTES = [
  "close",
  "max",
  "min",
  "name",
  "order",
  "public",
  "question",
  "results",
  "status",
  "type"
];

function replaceToken(tokens, target, list) {
  let pos = tokens.indexOf(target);
  let level = tokens[pos].level;

  tokens.splice(pos, 1, ...list);
  list[0].map = target.map;

  // resequence levels
  for (; pos < tokens.length; pos++) {
    let nesting = tokens[pos].nesting;
    if (nesting < 0) {
      level--;
    }
    tokens[pos].level = level;
    if (nesting > 0) {
      level++;
    }
  }
}

// analyzes the block so that we have survey options
function getListItems(tokens, startToken) {
  let i = tokens.length - 1;
  let listItems = [];
  let buffer = [];

  for (; tokens[i] !== startToken; i--) {
    if (i === 0) {
      return;
    }

    let token = tokens[i];
    if (token.tag === "li") {
      listItems.push([token, buffer.reverse().join(" ")]);
      buffer = [];
    } else {
      if (token.type === "text" || token.type === "inline") {
        buffer.push(token.content);
      }
    }
  }

  return listItems.reverse();
}

const surveyRule = {
  tag: 'survey',

  before: function(state, tagInfo) {
    let token = state.push("text", "", 0);
    token.attrs = [];
    token.bbcode_attrs = tagInfo.attrs;
    token.bbcode_type = "survey_open";
  },

  after: function(state, openToken) {
    const attrs = openToken.bbcode_attrs;

    // default survey attributes
    const attributes = [["class", "survey"]];

    WHITELISTED_ATTRIBUTES.forEach(name => {
      if (attrs[name]) {
        attributes.push([DATA_PREFIX + name, attrs[name]]);
      }
    });

    if (!attrs.name) {
      attributes.push([DATA_PREFIX + "name", DEFAULT_SURVEY_NAME]);
    }

    let header = [];
    let token = new state.Token("survey_open", "div", 1);
    token.block = true;
    token.attrs = attributes;
    header.push(token);

    replaceToken(state.tokens, openToken, header);
    state.push('survey_close', 'div', -1);
  }
}

const surveyRadioRule = {
  tag: "radio",

  before: function(state, tagInfo, raw) {
    let token = state.push("text", "", 0);
    token.attrs = [];
    token.bbcode_attrs = tagInfo.attrs;
    token.bbcode_type = "radio_open";
  },

  after: function(state, openToken) {
    const items = getListItems(state.tokens, openToken);
    const attrs = openToken.bbcode_attrs;
    const attributes = [["class", "survey-radio"]];
    attributes.push([DATA_PREFIX + "type", "radio"]);

    let question = attrs["question"];
    if (question) {
      let md5HashField = md5(JSON.stringify([question]));
      attributes.push([DATA_PREFIX + "field-id", md5HashField]);
    }

    WHITELISTED_ATTRIBUTES.forEach(name => {
      if (attrs[name]) {
        attributes.push([DATA_PREFIX + name, attrs[name]]);
      }
    });

    let header = [];
    let token = new state.Token("radio_open", "div", 1);
    token.block = true;
    token.attrs = attributes;
    header.push(token);

    for (let o = 0; o < items.length; o++) {
      let item_token = items[o][0];
      let text = items[o][1];

      item_token.attrs = item_token.attrs || [];
      let md5Hash = md5(JSON.stringify([text]));
      item_token.attrs.push([DATA_PREFIX + "option-id", md5Hash]);
    }

    replaceToken(state.tokens, openToken, header);
    state.level = state.tokens[state.tokens.length - 1].level;
    state.push("radio_close", "div", -1);
  }
};

const surveyCheckboxRule = {
  tag: "checkbox",

  before: function(state, tagInfo, raw) {
    let token = state.push("text", "", 0);
    token.attrs = [];
    token.bbcode_attrs = tagInfo.attrs;
    token.bbcode_type = "checkbox_open";
  },

  after: function(state, openToken) {
    const items = getListItems(state.tokens, openToken);
    const attrs = openToken.bbcode_attrs;
    const attributes = [["class", "survey-checkbox"]];
    attributes.push([DATA_PREFIX + "type", "checkbox"]);

    let question = attrs["question"];
    if (question) {
      let md5HashField = md5(JSON.stringify([question]));
      attributes.push([DATA_PREFIX + "field-id", md5HashField]);
    }

    WHITELISTED_ATTRIBUTES.forEach(name => {
      if (attrs[name]) {
        attributes.push([DATA_PREFIX + name, attrs[name]]);
      }
    });

    let header = [];
    let token = new state.Token("checkbox_open", "div", 1);
    token.block = true;
    token.attrs = attributes;
    header.push(token);

    for (let o = 0; o < items.length; o++) {
      let item_token = items[o][0];
      let text = items[o][1];

      item_token.attrs = item_token.attrs || [];
      let md5Hash = md5(JSON.stringify([text]));
      item_token.attrs.push([DATA_PREFIX + "option-id", md5Hash]);
    }

    replaceToken(state.tokens, openToken, header);
    state.level = state.tokens[state.tokens.length - 1].level;
    state.push("checkbox_close", "div", -1);
  }
};

const surveyDropdownRule = {
  tag: "dropdown",

  before: function(state, tagInfo, raw) {
    let token = state.push("text", "", 0);
    token.attrs = [];
    token.bbcode_attrs = tagInfo.attrs;
    token.bbcode_type = "dropdown_open";
  },

  after: function(state, openToken) {
    const items = getListItems(state.tokens, openToken);
    const attrs = openToken.bbcode_attrs;
    const attributes = [["class", "survey-dropdown"]];
    attributes.push([DATA_PREFIX + "type", "dropdown"]);

    let question = attrs["question"];
    if (question) {
      let md5HashField = md5(JSON.stringify([question]));
      attributes.push([DATA_PREFIX + "field-id", md5HashField]);
    }

    WHITELISTED_ATTRIBUTES.forEach(name => {
      if (attrs[name]) {
        attributes.push([DATA_PREFIX + name, attrs[name]]);
      }
    });

    let header = [];
    let token = new state.Token("dropdown_open", "div", 1);
    token.block = true;
    token.attrs = attributes;
    header.push(token);

    for (let o = 0; o < items.length; o++) {
      let item_token = items[o][0];
      let text = items[o][1];

      item_token.attrs = item_token.attrs || [];
      let md5Hash = md5(JSON.stringify([text]));
      item_token.attrs.push([DATA_PREFIX + "option-id", md5Hash]);
    }

    replaceToken(state.tokens, openToken, header);
    state.level = state.tokens[state.tokens.length - 1].level;
    state.push("dropdown_close", "div", -1);
  }
};

const surveyTextareaRule = {
  tag: "textarea",

  before: function(state, tagInfo) {
    let token = state.push("textarea", "", 0);
    token.attrs = [];
    token.bbcode_attrs = tagInfo.attrs;
    token.bbcode_type = "textarea_open";
  },

  after: function(state, openToken) {
    const attrs = openToken.bbcode_attrs;
    const attributes = [["class", "survey-textarea"]];
    attributes.push([DATA_PREFIX + "type", "textarea"]);

    let question = attrs["question"];
    if (question) {
      let md5HashField = md5(JSON.stringify([question]));
      attributes.push([DATA_PREFIX + "field-id", md5HashField]);
    }

    WHITELISTED_ATTRIBUTES.forEach(name => {
      if (attrs[name]) {
        attributes.push([DATA_PREFIX + name, attrs[name]]);
      }
    });

    let header = [];
    let token = new state.Token("textarea_open", "div", 1);
    token.block = true;
    token.attrs = attributes;
    header.push(token);

    replaceToken(state.tokens, openToken, header);
    state.level = state.tokens[state.tokens.length - 1].level;
    state.push("textarea_close", "div", -1);
  }
}

const surveyNumberRule = {
  tag: "number",

  before: function(state, tagInfo) {
    let token = state.push("number", "", 0);
    token.attrs = [];
    token.bbcode_attrs = tagInfo.attrs;
    token.bbcode_type = "number_open";
  },

  after: function(state, openToken) {
    const attrs = openToken.bbcode_attrs;
    const attributes = [["class", "survey-number"]];
    attributes.push([DATA_PREFIX + "type", "number"]);

    let question = attrs["question"];
    if (question) {
      let md5HashField = md5(JSON.stringify([question]));
      attributes.push([DATA_PREFIX + "field-id", md5HashField]);
    }

    WHITELISTED_ATTRIBUTES.forEach(name => {
      if (attrs[name]) {
        attributes.push([DATA_PREFIX + name, attrs[name]]);
      }
    });

    let header = [];
    let token = new state.Token("number_open", "div", 1);
    token.block = true;
    token.attrs = attributes;
    header.push(token);

    replaceToken(state.tokens, openToken, header);
    state.level = state.tokens[state.tokens.length - 1].level;
    state.push("number_close", "div", -1);
  }
}

function newApiInit(helper) {
  helper.registerOptions((opts, siteSettings) => {
    opts.features.survey = !!siteSettings.surveys_enabled;
    opts.surveyMaximumOptions = siteSettings.survey_maximum_options;
  });
  helper.registerPlugin(md => {
    md.block.bbcode.ruler.push("survey", surveyRule);
    md.block.bbcode.ruler.push("radio", surveyRadioRule);
    md.block.bbcode.ruler.push("checkbox", surveyCheckboxRule);
    md.block.bbcode.ruler.push("dropdown", surveyDropdownRule);
    md.block.bbcode.ruler.push("textarea", surveyTextareaRule);
    md.block.bbcode.ruler.push("number", surveyNumberRule);
  });
}

export function setup(helper) {
  helper.whiteList([
    "div.survey",
    "div.survey-radio",
    "div.survey-checkbox",
    "div.survey-dropdown",
    "div.survey-textarea",
    "div.survey-number",
    "div.survey-info",
    "div.survey-container",
    "div.survey-buttons",
    "div[data-*]",
    "span.info-number",
    "span.info-text",
    "span.info-label",
    "a.button.cast-votes",
    "a.button.toggle-results",
    "li[data-*]"
  ]);

  newApiInit(helper);
}

/*!
 * Joseph Myer's md5() algorithm wrapped in a self-invoked function to prevent
 * global namespace polution, modified to hash unicode characters as UTF-8.
 *
 * Copyright 1999-2010, Joseph Myers, Paul Johnston, Greg Holt, Will Bond <will@wbond.net>
 * http://www.myersdaily.org/joseph/javascript/md5-text.html
 * http://pajhome.org.uk/crypt/md5
 *
 * Released under the BSD license
 * http://www.opensource.org/licenses/bsd-license
 */
function md5cycle(x, k) {
  var a = x[0],
    b = x[1],
    c = x[2],
    d = x[3];

  a = ff(a, b, c, d, k[0], 7, -680876936);
  d = ff(d, a, b, c, k[1], 12, -389564586);
  c = ff(c, d, a, b, k[2], 17, 606105819);
  b = ff(b, c, d, a, k[3], 22, -1044525330);
  a = ff(a, b, c, d, k[4], 7, -176418897);
  d = ff(d, a, b, c, k[5], 12, 1200080426);
  c = ff(c, d, a, b, k[6], 17, -1473231341);
  b = ff(b, c, d, a, k[7], 22, -45705983);
  a = ff(a, b, c, d, k[8], 7, 1770035416);
  d = ff(d, a, b, c, k[9], 12, -1958414417);
  c = ff(c, d, a, b, k[10], 17, -42063);
  b = ff(b, c, d, a, k[11], 22, -1990404162);
  a = ff(a, b, c, d, k[12], 7, 1804603682);
  d = ff(d, a, b, c, k[13], 12, -40341101);
  c = ff(c, d, a, b, k[14], 17, -1502002290);
  b = ff(b, c, d, a, k[15], 22, 1236535329);

  a = gg(a, b, c, d, k[1], 5, -165796510);
  d = gg(d, a, b, c, k[6], 9, -1069501632);
  c = gg(c, d, a, b, k[11], 14, 643717713);
  b = gg(b, c, d, a, k[0], 20, -373897302);
  a = gg(a, b, c, d, k[5], 5, -701558691);
  d = gg(d, a, b, c, k[10], 9, 38016083);
  c = gg(c, d, a, b, k[15], 14, -660478335);
  b = gg(b, c, d, a, k[4], 20, -405537848);
  a = gg(a, b, c, d, k[9], 5, 568446438);
  d = gg(d, a, b, c, k[14], 9, -1019803690);
  c = gg(c, d, a, b, k[3], 14, -187363961);
  b = gg(b, c, d, a, k[8], 20, 1163531501);
  a = gg(a, b, c, d, k[13], 5, -1444681467);
  d = gg(d, a, b, c, k[2], 9, -51403784);
  c = gg(c, d, a, b, k[7], 14, 1735328473);
  b = gg(b, c, d, a, k[12], 20, -1926607734);

  a = hh(a, b, c, d, k[5], 4, -378558);
  d = hh(d, a, b, c, k[8], 11, -2022574463);
  c = hh(c, d, a, b, k[11], 16, 1839030562);
  b = hh(b, c, d, a, k[14], 23, -35309556);
  a = hh(a, b, c, d, k[1], 4, -1530992060);
  d = hh(d, a, b, c, k[4], 11, 1272893353);
  c = hh(c, d, a, b, k[7], 16, -155497632);
  b = hh(b, c, d, a, k[10], 23, -1094730640);
  a = hh(a, b, c, d, k[13], 4, 681279174);
  d = hh(d, a, b, c, k[0], 11, -358537222);
  c = hh(c, d, a, b, k[3], 16, -722521979);
  b = hh(b, c, d, a, k[6], 23, 76029189);
  a = hh(a, b, c, d, k[9], 4, -640364487);
  d = hh(d, a, b, c, k[12], 11, -421815835);
  c = hh(c, d, a, b, k[15], 16, 530742520);
  b = hh(b, c, d, a, k[2], 23, -995338651);

  a = ii(a, b, c, d, k[0], 6, -198630844);
  d = ii(d, a, b, c, k[7], 10, 1126891415);
  c = ii(c, d, a, b, k[14], 15, -1416354905);
  b = ii(b, c, d, a, k[5], 21, -57434055);
  a = ii(a, b, c, d, k[12], 6, 1700485571);
  d = ii(d, a, b, c, k[3], 10, -1894986606);
  c = ii(c, d, a, b, k[10], 15, -1051523);
  b = ii(b, c, d, a, k[1], 21, -2054922799);
  a = ii(a, b, c, d, k[8], 6, 1873313359);
  d = ii(d, a, b, c, k[15], 10, -30611744);
  c = ii(c, d, a, b, k[6], 15, -1560198380);
  b = ii(b, c, d, a, k[13], 21, 1309151649);
  a = ii(a, b, c, d, k[4], 6, -145523070);
  d = ii(d, a, b, c, k[11], 10, -1120210379);
  c = ii(c, d, a, b, k[2], 15, 718787259);
  b = ii(b, c, d, a, k[9], 21, -343485551);

  x[0] = add32(a, x[0]);
  x[1] = add32(b, x[1]);
  x[2] = add32(c, x[2]);
  x[3] = add32(d, x[3]);
}

function cmn(q, a, b, x, s, t) {
  a = add32(add32(a, q), add32(x, t));
  return add32((a << s) | (a >>> (32 - s)), b);
}

function ff(a, b, c, d, x, s, t) {
  return cmn((b & c) | (~b & d), a, b, x, s, t);
}

function gg(a, b, c, d, x, s, t) {
  return cmn((b & d) | (c & ~d), a, b, x, s, t);
}

function hh(a, b, c, d, x, s, t) {
  return cmn(b ^ c ^ d, a, b, x, s, t);
}

function ii(a, b, c, d, x, s, t) {
  return cmn(c ^ (b | ~d), a, b, x, s, t);
}

function md51(s) {
  // Converts the string to UTF-8 "bytes" when necessary
  if (/[\x80-\xFF]/.test(s)) {
    s = unescape(encodeURI(s));
  }
  var n = s.length,
    state = [1732584193, -271733879, -1732584194, 271733878],
    i;
  for (i = 64; i <= s.length; i += 64) {
    md5cycle(state, md5blk(s.substring(i - 64, i)));
  }
  s = s.substring(i - 64);
  var tail = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  for (i = 0; i < s.length; i++)
    tail[i >> 2] |= s.charCodeAt(i) << (i % 4 << 3);
  tail[i >> 2] |= 0x80 << (i % 4 << 3);
  if (i > 55) {
    md5cycle(state, tail);
    for (i = 0; i < 16; i++) tail[i] = 0;
  }
  tail[14] = n * 8;
  md5cycle(state, tail);
  return state;
}

function md5blk(s) {
  /* I figured global was faster.   */
  var md5blks = [],
    i; /* Andy King said do it this way. */
  for (i = 0; i < 64; i += 4) {
    md5blks[i >> 2] =
      s.charCodeAt(i) +
      (s.charCodeAt(i + 1) << 8) +
      (s.charCodeAt(i + 2) << 16) +
      (s.charCodeAt(i + 3) << 24);
  }
  return md5blks;
}

var hex_chr = "0123456789abcdef".split("");

function rhex(n) {
  var s = "",
    j = 0;
  for (; j < 4; j++)
    s += hex_chr[(n >> (j * 8 + 4)) & 0x0f] + hex_chr[(n >> (j * 8)) & 0x0f];
  return s;
}

function hex(x) {
  for (var i = 0; i < x.length; i++) x[i] = rhex(x[i]);
  return x.join("");
}

function add32(a, b) {
  return (a + b) & 0xffffffff;
}

function md5(s) {
  return hex(md51(s));
}
