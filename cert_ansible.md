```yaml
- name: Get PKI with highest TTL from Vault (via script on remote)
  hosts: my_remote_hosts
  gather_facts: false

  vars:
    vault_token: "{{ lookup('env','VAULT_TOKEN') }}"
    project: myproj
    vpc: nonlive
    environment: dev
    vault_addr: "https://vaultnp.sysman.corp.hmrc.gov.uk"  # or prod URL

  tasks:
    - name: Upload select_signer.sh
      ansible.builtin.copy:
        src: files/select_signer.sh        # put the script here alongside your playbook
        dest: /usr/local/bin/select_signer.sh
        mode: '0755'

    - name: Build query payload
      ansible.builtin.set_fact:
        signer_query:
          vault_token: "{{ vault_token }}"
          project: "{{ project }}"
          vpc: "{{ vpc }}"
          environment: "{{ environment }}"

    - name: Run select_signer.sh with JSON on stdin
      ansible.builtin.command: /bin/bash /usr/local/bin/select_signer.sh
      args:
        stdin: "{{ signer_query | to_json }}"
      environment:
        VAULT_ADDR: "{{ vault_addr }}"
      register: signer_raw
      changed_when: false
      no_log: true   # hides token

    - name: Parse JSON response
      ansible.builtin.set_fact:
        signer: "{{ signer_raw.stdout | from_json }}"
      failed_when: signer_raw.rc != 0 or (signer_raw.stdout | trim | length) == 0

    - name: Use the values
      ansible.builtin.debug:
        msg:
          - "PKI name: {{ signer.pki_name }}"
          - "TTL (seconds): {{ signer.pki_ttl }}"

```
