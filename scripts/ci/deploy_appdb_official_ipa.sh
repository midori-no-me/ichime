#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_YML="$ROOT_DIR/project.yml"
API_BASE_URL="${APPDB_API_BASE_URL:-https://api.dbservices.to/v1.7}"
MIN_TVOS_VERSION="${APPDB_MIN_TVOS_VERSION:-26.0}"
POLL_ATTEMPTS="${APPDB_POLL_ATTEMPTS:-60}"
POLL_INTERVAL_SECONDS="${APPDB_POLL_INTERVAL_SECONDS:-10}"
API_RETRIES="${APPDB_API_RETRIES:-5}"
API_RETRY_DELAY_SECONDS="${APPDB_API_RETRY_DELAY_SECONDS:-5}"
ANALYZED_IPA_SHA1=""

fail() {
  echo "::error::$*" >&2
  exit 1
}

warn() {
  echo "::warning::$*" >&2
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "$name is required"
}

extract_marketing_version() {
  awk '
    /^[[:space:]]*MARKETING_VERSION[[:space:]]*:/ {
      sub(/^[^:]*:/, "")
      sub(/[[:space:]]+#.*/, "")
      gsub(/^[[:space:]"]+|[[:space:]"]+$/, "")
      print
      exit
    }
  ' "$PROJECT_YML"
}

json_value() {
  local file="$1"
  local path="$2"

  python3 - "$file" "$path" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

value = data
for part in sys.argv[2].split("."):
    if part == "":
        continue
    if isinstance(value, list):
        value = value[int(part)]
    else:
        value = value[part]

if value is None:
    sys.exit(1)
if isinstance(value, (dict, list)):
    print(json.dumps(value, ensure_ascii=False))
else:
    print(value)
PY
}

json_array_value_by_key() {
  local file="$1"
  local array_path="$2"
  local key="$3"
  local expected="$4"
  local value_path="$5"

  python3 - "$file" "$array_path" "$key" "$expected" "$value_path" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

value = data
for part in sys.argv[2].split("."):
    if part == "":
        continue
    if isinstance(value, list):
        value = value[int(part)]
    else:
        value = value[part]

for item in value:
    if str(item.get(sys.argv[3])) != sys.argv[4]:
        continue

    selected = item
    for part in sys.argv[5].split("."):
        if part == "":
            continue
        if isinstance(selected, list):
            selected = selected[int(part)]
        else:
            selected = selected[part]

    if selected is None:
        sys.exit(1)
    if isinstance(selected, (dict, list)):
        print(json.dumps(selected, ensure_ascii=False))
    else:
        print(selected)
    sys.exit(0)

sys.exit(1)
PY
}

json_latest_array_value_by_key() {
  local file="$1"
  local array_path="$2"
  local key="$3"
  local expected="$4"
  local value_path="$5"

  python3 - "$file" "$array_path" "$key" "$expected" "$value_path" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

value = data
for part in sys.argv[2].split("."):
    if part == "":
        continue
    if isinstance(value, list):
        value = value[int(part)]
    else:
        value = value[part]

candidates = [item for item in value if str(item.get(sys.argv[3])) == sys.argv[4]]
candidates.sort(
    key=lambda item: (
        int(item.get("updated_at") or 0),
        int(item.get("id") or 0),
    ),
    reverse=True,
)

if not candidates:
    sys.exit(1)

selected = candidates[0]
for part in sys.argv[5].split("."):
    if part == "":
        continue
    if isinstance(selected, list):
        selected = selected[int(part)]
    else:
        selected = selected[part]

if selected is None:
    sys.exit(1)
if isinstance(selected, (dict, list)):
    print(json.dumps(selected, ensure_ascii=False))
else:
    print(selected)
PY
}

api_success() {
  local file="$1"

  python3 - "$file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

if data.get("success", True) is True:
    sys.exit(0)

print(json.dumps(data.get("errors", data), ensure_ascii=False), file=sys.stderr)
sys.exit(1)
PY
}

post_form() {
  local endpoint="$1"
  local response_file="$2"
  shift 2

  local http_code
  local curl_status
  local attempt

  for ((attempt = 1; attempt <= API_RETRIES; attempt++)); do
    : > "$response_file"
    curl_status=0
    http_code="$(curl -sS -w "%{http_code}" -o "$response_file" -X POST "$API_BASE_URL/$endpoint/" "$@")" || curl_status=$?

    if [[ "$curl_status" == "0" && "$http_code" =~ ^2 ]]; then
      api_success "$response_file" || fail "appdb /$endpoint/ returned an error"
      return
    fi

    if ((attempt < API_RETRIES)) && { [[ "$curl_status" != "0" ]] || [[ "$http_code" == "000" ]] || [[ "$http_code" =~ ^5 ]]; }; then
      warn "appdb /$endpoint/ request failed (curl=$curl_status, http=$http_code), retrying $attempt/$API_RETRIES"
      sleep "$API_RETRY_DELAY_SECONDS"
      continue
    fi

    [[ ! -s "$response_file" ]] || sed -n '1,200p' "$response_file" >&2
    fail "appdb /$endpoint/ returned HTTP $http_code (curl=$curl_status)"
  done
}

resolve_whatsnew() {
  if [[ -n "${APPDB_WHATSNEW:-}" ]]; then
    printf "%s" "$APPDB_WHATSNEW"
    return
  fi

  if [[ "${GITHUB_REF_TYPE:-}" == "tag" && -n "${GITHUB_REF_NAME:-}" ]] && command -v git >/dev/null; then
    local tag_body
    tag_body="$(git -C "$ROOT_DIR" for-each-ref "refs/tags/$GITHUB_REF_NAME" --format="%(contents)" | sed '/^[[:space:]]*$/d')"
    if [[ -n "$tag_body" ]]; then
      printf "%s" "$tag_body"
      return
    fi
  fi

  if command -v git >/dev/null; then
    local commit_body
    commit_body="$(git -C "$ROOT_DIR" log -1 --pretty=%B | sed '/^[[:space:]]*$/d')"
    if [[ -n "$commit_body" ]]; then
      printf "%s" "$commit_body"
      return
    fi
  fi

  printf "Release %s" "$PROJECT_VERSION"
}

validate_ref_version() {
  if [[ "${GITHUB_REF_TYPE:-}" == "tag" ]]; then
    [[ "${GITHUB_REF_NAME:-}" == "$PROJECT_VERSION" ]] || {
      fail "Git tag '${GITHUB_REF_NAME:-}' must match MARKETING_VERSION '$PROJECT_VERSION'"
    }
    return
  fi

  if [[ "${APPDB_ALLOW_NON_TAG_DEPLOY:-false}" == "true" ]]; then
    warn "Deploy is not running from a tag; using MARKETING_VERSION '$PROJECT_VERSION'"
    return
  fi

  fail "Deploy must run from a version tag matching MARKETING_VERSION. Set APPDB_ALLOW_NON_TAG_DEPLOY=true only for manual test runs."
}

poll_analyze_job() {
  local job_id="$1"
  local response_file="$2"

  for ((attempt = 1; attempt <= POLL_ATTEMPTS; attempt++)); do
    post_form "get_official_ipa_analyze_jobs" "$response_file" \
      --data-urlencode "st=$APPDB_ST" \
      --data-urlencode "brand=appdb" \
      --data-urlencode "lang=en" \
      --data-urlencode "ids[]=$job_id"

    local status
    local is_finished
    local issue
    local sha1_hash
    status="$(json_array_value_by_key "$response_file" "data" "id" "$job_id" "status" 2>/dev/null || true)"
    is_finished="$(json_array_value_by_key "$response_file" "data" "id" "$job_id" "is_finished" 2>/dev/null || echo "0")"
    issue="$(json_array_value_by_key "$response_file" "data" "id" "$job_id" "last_status_validation_issue" 2>/dev/null || true)"
    sha1_hash="$(json_array_value_by_key "$response_file" "data" "id" "$job_id" "sha1_hash" 2>/dev/null || true)"

    echo "appdb analyze job $job_id: ${status:-unknown} (attempt $attempt/$POLL_ATTEMPTS)"

    if [[ "$is_finished" == "1" ]]; then
      case "$status" in
        ok|success|validated|completed)
          [[ -z "$issue" ]] || echo "appdb analyze job note: $issue" >&2
          [[ -z "$sha1_hash" ]] || ANALYZED_IPA_SHA1="$sha1_hash"
          return
          ;;
        validation_failed|error|failed)
          if [[ -n "$issue" ]]; then
            fail "appdb analyze job failed: $issue"
          fi
          fail "appdb analyze job ended in '$status' status"
          ;;
        *)
          if [[ -n "$issue" ]]; then
            fail "appdb analyze job ended in '${status:-unknown}' status: $issue"
          fi
          fail "appdb analyze job ended in unexpected '${status:-unknown}' status"
          ;;
      esac
    fi

    sleep "$POLL_INTERVAL_SECONDS"
  done

  fail "Timed out waiting for appdb analyze job $job_id"
}

fetch_official_ipas() {
  local response_file="$1"
  local sha1_hash="${2:-}"
  local form_args=(
    --data-urlencode "st=$APPDB_ST"
    --data-urlencode "brand=appdb"
    --data-urlencode "lang=en"
    --data-urlencode "scope=$APPDB_APP_IDENTIFIER"
  )

  if [[ -n "$sha1_hash" ]]; then
    form_args+=(--data-urlencode "sha1_hash=$sha1_hash")
  fi

  post_form "get_official_ipas" "$response_file" "${form_args[@]}"
}

select_official_ipa_by_version() {
  local response_file="$1"
  local field="$2"

  json_latest_array_value_by_key "$response_file" "data" "bundle_version" "$PROJECT_VERSION" "$field" 2>/dev/null || true
}

find_existing_official_ipa() {
  local response_file="$1"
  local ipa_id
  local status

  fetch_official_ipas "$response_file"

  ipa_id="$(select_official_ipa_by_version "$response_file" "id")"
  [[ -n "$ipa_id" ]] || return 1

  status="$(select_official_ipa_by_version "$response_file" "status")"
  echo "Found existing appdb IPA $ipa_id for version $PROJECT_VERSION: ${status:-unknown}" >&2
  return 0
}

edit_ipa_metadata() {
  local ipa_id="$1"
  local response_file="$2"
  local description="${APPDB_DESCRIPTION:-Ichime is a native Anime 365 client for Apple TV.}"
  local whatsnew

  whatsnew="$(resolve_whatsnew)"

  echo "Updating appdb metadata for IPA $ipa_id" >&2
  post_form "edit_official_ipa_metadata" "$response_file" \
    --form-string "id=$ipa_id" \
    --form-string "st=$APPDB_ST" \
    --form-string "brand=appdb" \
    --form-string "lang=en" \
    --form-string "min_tvos_version=$MIN_TVOS_VERSION" \
    --form-string "description=$description" \
    --form-string "whatsnew=$whatsnew"
}

poll_official_ipa() {
  local sha1_hash="$1"
  local response_file="$2"
  local metadata_was_edited=0

  for ((attempt = 1; attempt <= POLL_ATTEMPTS; attempt++)); do
    local ipa_id
    local status
    local issue
    if [[ -n "$sha1_hash" ]]; then
      fetch_official_ipas "$response_file" "$sha1_hash"
      ipa_id="$(json_value "$response_file" "data.0.id" 2>/dev/null || true)"
      status="$(json_value "$response_file" "data.0.status" 2>/dev/null || true)"
      issue="$(json_value "$response_file" "data.0.last_status_validation_issue" 2>/dev/null || true)"
    else
      ipa_id=""
      status=""
      issue=""
    fi

    if [[ -z "$ipa_id" ]]; then
      fetch_official_ipas "$response_file"
      ipa_id="$(select_official_ipa_by_version "$response_file" "id")"
      status="$(select_official_ipa_by_version "$response_file" "status")"
      issue="$(select_official_ipa_by_version "$response_file" "last_status_validation_issue")"
    fi

    [[ -n "$ipa_id" ]] || {
      echo "appdb IPA is not visible yet (attempt $attempt/$POLL_ATTEMPTS)" >&2
      sleep "$POLL_INTERVAL_SECONDS"
      continue
    }

    echo "appdb IPA $ipa_id: ${status:-unknown} (attempt $attempt/$POLL_ATTEMPTS)" >&2

    case "$status" in
      ok)
        printf "%s" "$ipa_id"
        return
        ;;
      missing_metadata|incomplete_metadata)
        if [[ "$metadata_was_edited" == "0" ]]; then
          edit_ipa_metadata "$ipa_id" "$response_file"
          metadata_was_edited=1
        fi
        ;;
      processing_upload|pending_validation|validating|"")
        ;;
      validation_failed|duplicate|error)
        [[ -z "$issue" ]] || echo "appdb validation issue: $issue" >&2
        fail "appdb IPA $ipa_id ended in '$status' status"
        ;;
    esac

    sleep "$POLL_INTERVAL_SECONDS"
  done

  fail "Timed out waiting for appdb IPA with sha1 $sha1_hash"
}

assign_ipa_to_app() {
  local ipa_id="$1"
  local response_file="$2"

  echo "Assigning appdb IPA $ipa_id to app $APPDB_APP_IDENTIFIER"
  post_form "assign_ipa_to_app" "$response_file" \
    --data-urlencode "st=$APPDB_ST" \
    --data-urlencode "brand=appdb" \
    --data-urlencode "lang=en" \
    --data-urlencode "to_app_identifier=$APPDB_APP_IDENTIFIER" \
    --data-urlencode "ipa_id=$ipa_id"
}

command -v curl >/dev/null || fail "curl is required"
command -v python3 >/dev/null || fail "python3 is required"
command -v shasum >/dev/null || fail "shasum is required"
require_env "APPDB_ST"
require_env "APPDB_APP_IDENTIFIER"

IPA_PATH="${1:-}"
[[ -n "$IPA_PATH" ]] || fail "Usage: $0 path/to/app.ipa"
[[ -f "$IPA_PATH" ]] || fail "IPA does not exist: $IPA_PATH"

PROJECT_VERSION="$(extract_marketing_version)"
[[ -n "$PROJECT_VERSION" ]] || fail "Could not read MARKETING_VERSION from project.yml"
validate_ref_version

IPA_SHA1="$(shasum "$IPA_PATH" | awk '{print $1}')"
JOB_ID="$(printf "%s" "${GITHUB_REPOSITORY:-local}:$(basename "$IPA_PATH"):${GITHUB_RUN_ID:-manual}:${GITHUB_RUN_ATTEMPT:-1}:$IPA_SHA1" | shasum | awk '{print $1}')"
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "$RESPONSE_FILE"' EXIT

echo "Preparing $IPA_PATH for appdb"
echo "appdb job id: $JOB_ID"

if find_existing_official_ipa "$RESPONSE_FILE"; then
  echo "Reusing existing appdb IPA for version $PROJECT_VERSION"
  IPA_ID="$(poll_official_ipa "" "$RESPONSE_FILE")"
else
  echo "Uploading $IPA_PATH to appdb"
  post_form "add_official_ipa" "$RESPONSE_FILE" \
    -F "ipa=@$IPA_PATH" \
    --form-string "st=$APPDB_ST" \
    --form-string "brand=appdb" \
    --form-string "lang=en" \
    --form-string "job_id=$JOB_ID" \
    --form-string "scope=$APPDB_APP_IDENTIFIER"

  poll_analyze_job "$JOB_ID" "$RESPONSE_FILE"
  IPA_ID="$(poll_official_ipa "${ANALYZED_IPA_SHA1:-$IPA_SHA1}" "$RESPONSE_FILE")"
fi

assign_ipa_to_app "$IPA_ID" "$RESPONSE_FILE"

echo "Assigned appdb IPA $IPA_ID to $APPDB_APP_IDENTIFIER"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "job_id=$JOB_ID"
    echo "ipa_id=$IPA_ID"
  } >> "$GITHUB_OUTPUT"
fi
