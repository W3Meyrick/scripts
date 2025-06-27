```yaml
- name: Add auto-restart to existing systemd unit
  hosts: all
  become: yes
  tasks:

    - name: Ensure 'Restart=always' in [Service] section
      ansible.builtin.lineinfile:
        path: /etc/systemd/system/myapp.service
        insertafter: '^\[Service\]'
        regexp: '^Restart='
        line: 'Restart=always'
        state: present

    - name: Ensure 'RestartSec=5' in [Service] section
      ansible.builtin.lineinfile:
        path: /etc/systemd/system/myapp.service
        insertafter: '^\[Service\]'
        regexp: '^RestartSec='
        line: 'RestartSec=5'
        state: present

    - name: Reload systemd
      ansible.builtin.systemd:
        daemon_reload: yes

    - name: Restart and enable service
      ansible.builtin.systemd:
        name: myapp
        state: restarted
        enabled: yes
```
