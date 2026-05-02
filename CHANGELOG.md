# Changelog

## [2.2.3](https://github.com/rizz360/ts-to-mkv/compare/ts-to-mkv-v2.2.2...ts-to-mkv-v2.2.3) (2026-05-02)


### Bug Fixes

* **ci:** prevent malformed ghcr tag in release publish ([0691094](https://github.com/rizz360/ts-to-mkv/commit/06910940ab60c9ac7d9d9de02112a1bb44617dca))
* **ci:** prevent malformed ghcr tag in release publish ([7a97225](https://github.com/rizz360/ts-to-mkv/commit/7a972254239637aefb98d2aeae6fd08c36681b14))

## [2.2.2](https://github.com/rizz360/ts-to-mkv/compare/ts-to-mkv-v2.2.1...ts-to-mkv-v2.2.2) (2026-05-02)


### Bug Fixes

* Improve ntfy webhook handling with conservative curl timeouts ([d744fa1](https://github.com/rizz360/ts-to-mkv/commit/d744fa13042c08bd6c1d194278d1f38513968446))
* **logging:** bound ntfy webhook call time ([ff565ee](https://github.com/rizz360/ts-to-mkv/commit/ff565eeda4fd1b20a7323b0b95e9bb821afd8c48))

## [2.2.1](https://github.com/rizz360/ts-to-mkv/compare/ts-to-mkv-v2.2.0...ts-to-mkv-v2.2.1) (2026-05-02)


### Bug Fixes

* **ci:** preserve original tag names and guard latest against pre-releases ([4271f69](https://github.com/rizz360/ts-to-mkv/commit/4271f69b1cf46560c9be203e5cbf746041d78518))
* **ci:** publish GHCR image on release-please tags ([58f6f39](https://github.com/rizz360/ts-to-mkv/commit/58f6f39887207aeccc6be4be47813625380f8305))
* **ci:** publish GHCR image on release-please tags ([5520daa](https://github.com/rizz360/ts-to-mkv/commit/5520daa5da24bdddf97df48d6966a7f9df489b8c))

## [2.2.0](https://github.com/rizz360/ts-to-mkv/compare/ts-to-mkv-v2.1.0...ts-to-mkv-v2.2.0) (2026-05-02)


### Features

* add initial .env configuration for encoding settings and processing options ([2d3e714](https://github.com/rizz360/ts-to-mkv/commit/2d3e714595546fc5e318cf10eb26b3c51187e3be))


### Bug Fixes

* address review feedback on config path, compose vars, and doc placeholders ([2ba648a](https://github.com/rizz360/ts-to-mkv/commit/2ba648a7edeeccff66a41be4002940bef1eb5273))

## [2.1.0](https://github.com/rizz360/ts-to-mkv/compare/ts-to-mkv-v2.0.0...ts-to-mkv-v2.1.0) (2026-05-01)


### Features

* **docker:** default to GHCR pull + env_file config ([31c4f28](https://github.com/rizz360/ts-to-mkv/commit/31c4f281489783041637be09dc4d21482fd4126a))
* Update configuration handling in Docker setup for improved clarity and flexibility ([20fab10](https://github.com/rizz360/ts-to-mkv/commit/20fab1087328f99a7b017192c439744a73d18f68))
* Update Docker setup for improved image handling and local development support ([fbed0c1](https://github.com/rizz360/ts-to-mkv/commit/fbed0c10dd87cfc2b6e90a61255b5d35c9093c5a))


### Bug Fixes

* convert config/.env to Compose-compatible format and gate latest tag to stable releases ([21ad221](https://github.com/rizz360/ts-to-mkv/commit/21ad221630d0f5442a48858d3bfc5f71fb3fb079))

## [2.0.0](https://github.com/rizz360/ts-to-mkv/compare/ts-to-mkv-v1.2.0...ts-to-mkv-v2.0.0) (2026-05-01)


### ⚠ BREAKING CHANGES

* cleanup.env format updated with new configuration options

### Features

* Add automatic codec fallback to handle QSV hardware encoding failures ([43275be](https://github.com/rizz360/ts-to-mkv/commit/43275be6e414ff2f7905959a51ca69a986e891aa))
* Add CI and Release workflows for automated testing and image publishing ([7204ccc](https://github.com/rizz360/ts-to-mkv/commit/7204ccc957cb203ff0fb86d0dd12517b195a9da2))
* Add continuous file monitoring to prevent container restart loops ([6c837b8](https://github.com/rizz360/ts-to-mkv/commit/6c837b8113ba5114ce7551778e0d419ed8c63fe3))
* add guidelines for handling filenames safely in shell scripts ([023cc45](https://github.com/rizz360/ts-to-mkv/commit/023cc456e41e6eabc5e5df0f2b51bd52c1fb0473))
* Add release configuration and manifest files for automated releases ([606e19d](https://github.com/rizz360/ts-to-mkv/commit/606e19d06fd272669d4298487b23741075a53777))
* Add smoke integration test for modular processing flow ([ff3f58c](https://github.com/rizz360/ts-to-mkv/commit/ff3f58cc5bc8e681c222392fa2867f2fdb04b6fc))
* add temporary file management for processing and cleanup ([5dfd238](https://github.com/rizz360/ts-to-mkv/commit/5dfd2387d2e7f10ea972e0e716851378c45a3886))
* Implement modular architecture for TS-to-MKV processor ([a845ad5](https://github.com/rizz360/ts-to-mkv/commit/a845ad5a552a30ffa2c5a0be16bf87ca78c0b9f9))
* optimize video encoding with resolution-adaptive parameters ([1074309](https://github.com/rizz360/ts-to-mkv/commit/1074309e44608ebb4a0bd9a8e5af785cf5375b47))


### Bug Fixes

* add -- to mktemp and || return 1 to mkdir in create_temp_job_dir ([8f0f4de](https://github.com/rizz360/ts-to-mkv/commit/8f0f4de7aeabc08057f66023d716cd168b804a14))
* address PR review feedback on docs links, README layout tree, and rg dep check ([fec7963](https://github.com/rizz360/ts-to-mkv/commit/fec7963fabcd2afd8cdbb4c4ee2f2947df774a53))
* improve file processing in cleanup script to handle special characters ([4a0e638](https://github.com/rizz360/ts-to-mkv/commit/4a0e638b977693941246ffebc0cbdd30aa6db5ba))
* support series paths safely in parallel jobs ([412adde](https://github.com/rizz360/ts-to-mkv/commit/412addeda10e3860d5b17ab0a717ee24ed1571aa))
* support series paths safely in parallel jobs ([36a0488](https://github.com/rizz360/ts-to-mkv/commit/36a04887a4d5c7a85bfa815835e830e2a6f03631))
