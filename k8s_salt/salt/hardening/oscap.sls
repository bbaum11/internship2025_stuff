create_tailor_file:
  cmd.run:
    - name: |
        autotailor \
          -u xccdf_org.ssgproject.content_rule_package_httpd_removed \
          -u xccdf_org.ssgproject.content_rule_package_dnsmasq_removed \
          -u xccdf_org.ssgproject.content_rule_account_disable_post_pw_expiration \
          -u xccdf_org.ssgproject.content_rule_accounts_maximum_age_login_defs \
          -u xccdf_org.ssgproject.content_rule_accounts_minimum_age_login_defs \
          -u xccdf_org.ssgproject.content_rule_accounts_password_set_max_life_existing \
          -u xccdf_org.ssgproject.content_rule_accounts_password_set_min_life_existing \
          -u xccdf_org.ssgproject.content_rule_accounts_password_set_warn_age_existing \
          -u xccdf_org.ssgproject.content_rule_accounts_password_warn_age_login_defs \
          -u xccdf_org.ssgproject.content_rule_accounts_set_post_pw_existing \
          -u xccdf_org.ssgproject.content_rule_accounts_password_pam_minclass \
          -u xccdf_org.ssgproject.content_rule_accounts_password_pam_minlen \
          -u xccdf_org.ssgproject.content_rule_accounts_password_pam_retry \
          -u xccdf_org.ssgproject.content_rule_package_firewalld_installed \
          -u xccdf_org.ssgproject.content_rule_service_firewalld_enabled \
          -u xccdf_org.ssgproject.content_rule_firewalld_loopback_traffic_restricted \
          -u xccdf_org.ssgproject.content_rule_firewalld_loopback_traffic_trusted \
          -o /tmp/tailor-file.xml \
          -p tailored-for-k8s \
          /usr/share/xml/scap/ssg/content/ssg-rl9-ds.xml \
          xccdf_org.ssgproject.content_profile_cis_server_l1
    - creates: /tmp/tailor-file.xml

generate_remediation_script:
  cmd.run:
    - name: oscap xccdf generate fix --output /tmp/draft-remediation.sh --profile tailored-for-k8s --tailoring-file /tmp/tailor-file.xml /usr/share/xml/scap/ssg/content/ssg-rl9-ds.xml
    - require:
      - cmd: create_tailor_file

/tmp/draft-remediation.sh:
  file.managed:
    - mode: 700
    - require:
      - cmd: generate_remediation_script
    - replace: False

run_remediation_script:
  cmd.run:
    - name: /tmp/draft-remediation.sh
    - require:
      - file: /tmp/draft-remediation.sh