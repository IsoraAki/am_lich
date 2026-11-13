fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android fetch_version_code_from_play_store

```sh
[bundle exec] fastlane android fetch_version_code_from_play_store
```



### android get_local_version_code

```sh
[bundle exec] fastlane android get_local_version_code
```



### android compare_version_codes

```sh
[bundle exec] fastlane android compare_version_codes
```



### android bump_version_code

```sh
[bundle exec] fastlane android bump_version_code
```



### android set_version_code

```sh
[bundle exec] fastlane android set_version_code
```



### android get_version_name

```sh
[bundle exec] fastlane android get_version_name
```

Get the version name of the current project

### android update_version_name

```sh
[bundle exec] fastlane android update_version_name
```

Manually update version name

### android build_aab

```sh
[bundle exec] fastlane android build_aab
```

Build the release AAB without uploading it

### android upload_to_chplay

```sh
[bundle exec] fastlane android upload_to_chplay
```

Upload the AAB to Google Play

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
