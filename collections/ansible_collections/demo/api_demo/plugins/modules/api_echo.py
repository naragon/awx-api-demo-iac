#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import annotations

DOCUMENTATION = r"""
---
module: api_echo
short_description: Call an HTTP API endpoint and return response details
version_added: "0.1.0"
description:
  - Sends a GET or POST request to an HTTP endpoint.
  - Intended as a simple demo module for validating AWX custom execution environments.
options:
  url:
    description:
      - HTTP URL to call.
    type: str
    required: false
    default: https://httpbin.org/anything
  method:
    description:
      - HTTP method to use.
    type: str
    required: false
    default: GET
    choices:
      - GET
      - POST
  params:
    description:
      - Query parameters to append to the URL.
    type: dict
    required: false
  body:
    description:
      - Request body for POST requests.
      - Can be a dictionary (sent as JSON) or a string.
    type: raw
    required: false
  headers:
    description:
      - Additional HTTP headers.
    type: dict
    required: false
  timeout:
    description:
      - Request timeout in seconds.
    type: int
    required: false
    default: 10
author:
  - naragon
"""

EXAMPLES = r"""
- name: GET to echo endpoint
  demo.api_demo.api_echo:
    url: https://httpbin.org/anything
    method: GET
    params:
      source: awx

- name: POST JSON to echo endpoint
  demo.api_demo.api_echo:
    url: https://httpbin.org/anything
    method: POST
    body:
      hello: world
"""

RETURN = r"""
changed:
  description: Always false for this demo module.
  type: bool
  returned: always
status_code:
  description: HTTP status code returned by the endpoint.
  type: int
  returned: always
response_json:
  description: Parsed JSON response when available.
  type: dict
  returned: when JSON body is returned
response_text:
  description: Raw response body text.
  type: str
  returned: always
headers:
  description: Response headers.
  type: dict
  returned: always
elapsed_ms:
  description: Request duration in milliseconds.
  type: int
  returned: always
request_summary:
  description: Method and URL used.
  type: dict
  returned: always
"""

from ansible.module_utils.basic import AnsibleModule


def run_module() -> None:
    module_args = {
        "url": {"type": "str", "required": False, "default": "https://httpbin.org/anything"},
        "method": {"type": "str", "required": False, "default": "GET", "choices": ["GET", "POST"]},
        "params": {"type": "dict", "required": False, "default": {}},
        "body": {"type": "raw", "required": False, "default": None},
        "headers": {"type": "dict", "required": False, "default": {}},
        "timeout": {"type": "int", "required": False, "default": 10},
    }

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    if module.check_mode:
        module.exit_json(
            changed=False,
            skipped=True,
            msg="Check mode: request not sent",
            request_summary={"method": module.params["method"], "url": module.params["url"]},
        )

    url = module.params["url"]
    method = module.params["method"]
    params = module.params["params"]
    body = module.params["body"]
    headers = module.params["headers"]
    timeout = module.params["timeout"]

    try:
        import requests  # type: ignore
    except Exception as exc:
        module.fail_json(msg=f"python package 'requests' is required in the execution environment: {exc}")

    request_kwargs = {
        "params": params,
        "headers": headers,
        "timeout": timeout,
    }

    if method == "POST":
        if isinstance(body, dict):
            request_kwargs["json"] = body
        elif body is not None:
            request_kwargs["data"] = body

    try:
        response = requests.request(method, url, **request_kwargs)
    except Exception as exc:
        module.fail_json(msg=f"Request failed: {exc}", request_summary={"method": method, "url": url})

    try:
        response_json = response.json()
    except Exception:
        response_json = None

    result = {
        "changed": False,
        "status_code": response.status_code,
        "response_json": response_json,
        "response_text": response.text,
        "headers": dict(response.headers),
        "elapsed_ms": int(response.elapsed.total_seconds() * 1000),
        "request_summary": {"method": method, "url": url},
    }

    if response.status_code >= 400:
        module.fail_json(msg=f"HTTP error status returned: {response.status_code}", **result)

    module.exit_json(**result)


def main() -> None:
    run_module()


if __name__ == "__main__":
    main()
