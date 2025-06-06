#{% set common_programs = salt["pillar.get"]("common_programs"), [] %}
#{% set wks_programs = salt["pillar.get"]("wks_programs"), [] %}
#{% set k8s_master_programs = salt["pillar.get"]("k8s_master_programs"), [] %}
#{% set k8s_minion_programs = salt["pillar.get"]("k8s_minion_programs"), [] %}
#{% set programs = common_programs + wks_programs + k8s_master_programs + k8s_minion_programs %}

{% set programs = ['createrepo_c','yum-utils','vim'] %}

install:
  pkg.installed:
    - pkgs: {{programs}}
    - refresh: true