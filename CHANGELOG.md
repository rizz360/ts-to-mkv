# Changelog

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
