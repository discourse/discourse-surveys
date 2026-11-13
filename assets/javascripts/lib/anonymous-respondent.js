const TOKEN_KEY = "discourse_surveys_anonymous_id";
const SUBMITTED_KEY = "discourse_surveys_submitted";

// Must stay in sync with DiscourseSurveys::Helper::ANON_TOKEN_FORMAT
const TOKEN_FORMAT = /^[a-zA-Z0-9_-]{16,64}$/;

function read(key) {
  try {
    return window.localStorage.getItem(key);
  } catch {
    // localStorage throws in private browsing and sandboxed frames
    return null;
  }
}

function write(key, value) {
  try {
    window.localStorage.setItem(key, value);
  } catch {
    // not persistable; callers degrade to per-page-load behaviour
  }
}

function generateToken() {
  if (typeof crypto?.randomUUID === "function") {
    return crypto.randomUUID();
  }

  // randomUUID needs a secure context, getRandomValues does not
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

let sessionToken;

/**
 * Stable per-browser identifier for an anonymous respondent.
 * Falls back to a token that only lives as long as the page when it cannot be persisted.
 *
 * @returns {string}
 */
export function anonymousToken() {
  const stored = read(TOKEN_KEY);
  if (stored && TOKEN_FORMAT.test(stored)) {
    return stored;
  }

  sessionToken ??= generateToken();
  write(TOKEN_KEY, sessionToken);
  return sessionToken;
}

function submissionKey(postId, surveyName) {
  return `${postId}:${surveyName}`;
}

function readSubmissions() {
  try {
    const parsed = JSON.parse(read(SUBMITTED_KEY) ?? "[]");
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

/**
 * Whether this browser has already submitted a given survey. Only meaningful for
 * anonymous respondents — logged-in users get `user_responded` from the server.
 *
 * @param {number} postId
 * @param {string} surveyName
 * @returns {boolean}
 */
export function hasSubmitted(postId, surveyName) {
  return readSubmissions().includes(submissionKey(postId, surveyName));
}

/**
 * @param {number} postId
 * @param {string} surveyName
 */
export function markSubmitted(postId, surveyName) {
  const submissions = readSubmissions();
  const key = submissionKey(postId, surveyName);

  if (!submissions.includes(key)) {
    write(SUBMITTED_KEY, JSON.stringify([...submissions, key]));
  }
}
