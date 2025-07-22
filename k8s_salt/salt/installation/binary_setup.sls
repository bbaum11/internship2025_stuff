/usr/local/bin/k9s:
    file.managed:
        - source: salt://files/server/binaries/k9s
        - mode: 700

/usr/local/bin/helm:
    file.managed:
        - source: salt://files/server/binaries/helm
        - mode: 700