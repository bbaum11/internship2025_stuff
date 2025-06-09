{% set common_programs = pillar.get('common_programs', []) %}
{% set wks_programs = pillar.get('wks_programs', []) %}
{% set k8s_master_programs = pillar.get('k8s_master_programs', []) %}
{% set k8s_minion_programs = pillar.get('k8s_minion_programs', []) %}
{% set programs = common_programs + wks_programs + k8s_master_programs + k8s_minion_programs + ['createrepo']%}

#{% set programs = ['createrepo','yum_utils','vim'] %}

install:
  pkg.installed:
    - pkgs: {{programs}}
    - refresh: true