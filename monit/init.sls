{% from "monit/map.jinja" import monit with context %}

{{ monit.conf_dir }}:
  file.directory:
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - recurse:
        - user
        - group
        - mode
        - ignore_files

monitrc-file:
  file.managed:
    - name: {{ monit.conf_dir }}/monitrc
    - source: salt://monit/files/monitrc
    - template: jinja
    - user: root
    - mode: 600
    - context:
      confd_dir: {{ monit.confd_dir }}
    - watch_in:
      - service: monit
    - require:
      - file: {{ monit.conf_dir }}

monit-pkg-install:
  pkg:
    - name: {{ monit.pkg }}
    - installed
    - require:
      - file: {{ monit.conf_dir }}/monitrc

confd_dir:
  file.directory:
    - name: {{ monit.confd_dir }}
    - user: root
    - group: root
    - mode: 0755
    - require:
      - file: {{ monit.conf_dir }}

{% if grains['os'] == 'Debian' %}
upstart:
  file.managed:
    - name: /etc/init/monit.conf
    - source: salt://monit/files/upstart_monit.conf
    - user: root
    - group: root
    - mode: 0444
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
rc_logging:
  file.absent:
    - name: {{ monit.confd_dir }}/logging
{% endif %}

service:
  service.running:
    - enable: True
    - name: {{ monit.service }}
    - require:
      - pkg: {{ monit.pkg }}
      - file: {{ monit.conf_dir }}/monitrc
    - watch:
      - file: {{ monit.conf_dir }}/monitrc
      - file: {{ monit.confd_dir }}
