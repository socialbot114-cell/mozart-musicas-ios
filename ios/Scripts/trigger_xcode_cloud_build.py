#!/usr/bin/env python3
"""Start an Xcode Cloud build for this repository's selected branch."""

from __future__ import annotations

import json
import os
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

import jwt


API_ROOT = "https://api.appstoreconnect.apple.com/v1"
BUNDLE_ID = "br.com.musicaspara.estudar"
REPOSITORY_OWNER = "socialbot114-cell"
REPOSITORY_NAME = "mozart-musicas-ios"


def make_token() -> str:
    key_id = os.environ["APPLE_API_KEY_ID"]
    issuer_id = os.environ["APPLE_API_ISSUER_ID"]
    private_key = os.environ["APPLE_API_KEY_P8"]
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer_id, "iat": now, "exp": now + 15 * 60, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


TOKEN = make_token()


def api_request(path: str, method: str = "GET", body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    request = Request(
        path if path.startswith("https://") else f"{API_ROOT}{path}",
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {TOKEN}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
    )
    try:
        with urlopen(request, timeout=30) as response:
            return json.load(response)
    except HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        try:
            messages = [item.get("detail", "") for item in json.loads(detail).get("errors", [])]
        except (json.JSONDecodeError, AttributeError):
            messages = []
        reason = "; ".join(message for message in messages if message) or "Apple returned an API error"
        raise RuntimeError(f"App Store Connect API returned HTTP {error.code}: {reason}") from None
    except URLError as error:
        raise RuntimeError(f"Could not reach App Store Connect: {error.reason}") from None


def list_pages(path: str) -> list[dict]:
    items: list[dict] = []
    next_url: str | None = path
    while next_url:
        response = api_request(next_url)
        items.extend(response.get("data", []))
        next_url = response.get("links", {}).get("next")
    return items


def related_app_id(ci_product_id: str) -> str | None:
    response = api_request(f"/ciProducts/{ci_product_id}/app")
    app = response.get("data")
    return app.get("id") if app else None


def select_workflow(product_id: str, requested_name: str | None) -> dict:
    query = urlencode({"limit": "200"})
    workflows = list_pages(f"/ciProducts/{product_id}/workflows?{query}")
    enabled = [workflow for workflow in workflows if workflow.get("attributes", {}).get("isEnabled", True)]

    if requested_name:
        matches = [workflow for workflow in enabled if workflow.get("attributes", {}).get("name") == requested_name]
        if len(matches) != 1:
            choices = ", ".join(workflow.get("attributes", {}).get("name", "(unnamed)") for workflow in enabled)
            raise RuntimeError(f"No unique enabled workflow named {requested_name!r}. Available: {choices or '(none)'}")
        return matches[0]

    if len(enabled) != 1:
        choices = ", ".join(workflow.get("attributes", {}).get("name", "(unnamed)") for workflow in enabled)
        raise RuntimeError(f"Expected one enabled Xcode Cloud workflow; found {len(enabled)}: {choices or '(none)'}")
    return enabled[0]


def select_repository() -> dict:
    repositories = list_pages("/scmRepositories?limit=200")
    matches = []
    for repository in repositories:
        values = " ".join(str(value) for value in repository.get("attributes", {}).values()).lower()
        if REPOSITORY_NAME in values and REPOSITORY_OWNER in values:
            matches.append(repository)
    if len(matches) != 1:
        raise RuntimeError(
            f"Expected one Xcode Cloud repository for {REPOSITORY_OWNER}/{REPOSITORY_NAME}; found {len(matches)}"
        )
    return matches[0]


def select_branch(repository_id: str, branch_name: str) -> dict:
    query = urlencode({"limit": "200"})
    references = list_pages(f"/scmRepositories/{repository_id}/gitReferences?{query}")
    matches = []
    for reference in references:
        attrs = reference.get("attributes", {})
        names = {str(attrs.get(key, "")) for key in ("name", "canonicalName")}
        if branch_name in names or f"refs/heads/{branch_name}" in names:
            if not attrs.get("isDeleted", False):
                matches.append(reference)
    if len(matches) != 1:
        raise RuntimeError(
            f"Xcode Cloud does not have a unique Git reference for branch {branch_name!r}; found {len(matches)}"
        )
    return matches[0]


def main() -> None:
    bundle_query = urlencode({"filter[bundleId]": BUNDLE_ID, "limit": "200"})
    apps = list_pages(f"/apps?{bundle_query}")
    if len(apps) != 1:
        raise RuntimeError(f"Expected one App Store Connect app with bundle ID {BUNDLE_ID}; found {len(apps)}")
    app = apps[0]

    products = list_pages("/ciProducts?limit=200")
    products_for_app = [product for product in products if related_app_id(product["id"]) == app["id"]]
    if len(products_for_app) != 1:
        raise RuntimeError(
            f"Expected one Xcode Cloud product for {BUNDLE_ID}; found {len(products_for_app)}. "
            "Create/connect an Xcode Cloud workflow in App Store Connect first."
        )
    product = products_for_app[0]

    workflow_name = os.environ.get("XCODE_CLOUD_WORKFLOW_NAME", "").strip() or None
    workflow = select_workflow(product["id"], workflow_name)
    repository = select_repository()
    branch = os.environ["GITHUB_REF_NAME"]
    git_reference = select_branch(repository["id"], branch)

    request_body = {
        "data": {
            "type": "ciBuildRuns",
            "attributes": {},
            "relationships": {
                "workflow": {"data": {"type": "ciWorkflows", "id": workflow["id"]}},
                "sourceBranchOrTag": {"data": {"type": "scmGitReferences", "id": git_reference["id"]}},
            },
        }
    }
    build = api_request("/ciBuildRuns", method="POST", body=request_body)["data"]
    attrs = build.get("attributes", {})
    source_commit = attrs.get("sourceCommit", {}).get("commitSha", "unknown")
    workflow_label = workflow.get("attributes", {}).get("name", workflow["id"])
    summary = (
        f"### Xcode Cloud build started\n"
        f"- App: `{BUNDLE_ID}`\n"
        f"- Workflow: `{workflow_label}`\n"
        f"- Branch: `{branch}`\n"
        f"- Source commit: `{source_commit}`\n"
        f"- Build run ID: `{build['id']}`\n"
        f"- Progress: `{attrs.get('executionProgress', 'PENDING')}`\n"
    )
    print(summary)
    summary_file = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_file:
        with open(summary_file, "a", encoding="utf-8") as file:
            file.write(summary)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"::error::{error}")
        sys.exit(1)
