```yaml
# playbooks/select_signer.yml
- name: Get PKI with highest TTL from Vault (via existing script)
  hosts: localhost
  gather_facts: false

  vars:
    vault_token: "{{ lookup('env','VAULT_TOKEN') }}"   # or set explicitly
    project: myproj
    vpc: nonlive                                      # or 'live'
    environment: dev

  tasks:
    - name: Build query payload (same shape as Terraform 'query')
      set_fact:
        signer_query:
          vault_token: "{{ vault_token }}"
          project: "{{ project }}"
          vpc: "{{ vpc }}"
          environment: "{{ environment }}"

    - name: Run select_signer.sh (send JSON on stdin, capture stdout)
      ansible.builtin.command: /bin/bash ./select_signer.sh
      args:
        stdin: "{{ signer_query | to_json }}"
      environment:
        # Your script expects VAULT_ADDR (and derives namespace internally)
        VAULT_ADDR: "https://vaultnp.sysman.corp.hmrc.gov.uk"  # or prod URL
      register: signer_raw
      changed_when: false
      no_log: true   # hides token in logs

    - name: Parse JSON response from script
      set_fact:
        signer: "{{ signer_raw.stdout | from_json }}"
      failed_when: signer_raw.rc != 0 or (signer_raw.stdout | length) == 0

    - name: Use the values
      debug:
        msg:
          - "PKI name: {{ signer.pki_name }}"
          - "TTL (seconds): {{ signer.pki_ttl }}"
          - "TTL (days, floor): {{ (signer.pki_ttl | int) // 86400 }}"

```
