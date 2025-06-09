{% set programs = salt["pillar.get"]("common_programs") %}
{% for program in programs %}

download_rpms:
  cmd.run:
    - name: "dnf download --alldep --resolve --downloaddir=/srv/repo {{program}}"
    - unless:
        - ls /srv/repo/{{program}}
{% endfor %}
run_createrepo:
    cmd.run:
        - name: createrepo /srv/repo