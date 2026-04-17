# demo.api_demo

Demo Ansible collection containing a single module, `api_echo`, used to validate custom Execution Environments (EEs) in AWX.

## Module

- `demo.api_demo.api_echo`

## Example

```yaml
- name: API echo demo
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Call httpbin
      demo.api_demo.api_echo:
        url: https://httpbin.org/anything
        method: GET
        params:
          source: awx
      register: api_result

    - debug:
        var: api_result
```
