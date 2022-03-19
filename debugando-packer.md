
- Debugando o packer usando o "PACKER_LOG=1":
PACKER_LOG=1 packer build -var 'release=v0.7.1' .

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ PACKER_LOG=1 packer build -var 'release=v0.7.1' .
2022/03/19 13:00:53 [INFO] Packer version: 1.8.0 [go1.17.8 linux amd64]
2022/03/19 13:00:53 [TRACE] discovering plugins in /usr/bin
2022/03/19 13:00:53 [TRACE] discovering plugins in /home/fernando/.config/packer/plugins
2022/03/19 13:00:53 [TRACE] discovering plugins in .
2022/03/19 13:00:53 [INFO] PACKER_CONFIG env var not set; checking the default config file path
2022/03/19 13:00:53 [INFO] PACKER_CONFIG env var set; attempting to open config file: /home/fernando/.packerconfig
2022/03/19 13:00:53 [WARN] Config file doesn t exist: /home/fernando/.packerconfig
2022/03/19 13:00:53 [INFO] Setting cache directory: /home/fernando/.cache/packer
2022/03/19 13:00:53 [TRACE] validateValue: not active for release, so skipping

2022/03/19 13:00:53 Build debug mode: false
2022/03/19 13:00:53 Force build: false
2022/03/19 13:00:53 On error:
2022/03/19 13:00:53 Waiting on builds to complete...
==> Wait completed after 4 microseconds
==> Builds finished but no artifacts were created.
2022/03/19 13:00:53 [INFO] (telemetry) Finalizing.
==> Wait completed after 4 microseconds

==> Builds finished but no artifacts were created.
2022/03/19 13:00:54 waiting for all plugin processes to complete...
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~


