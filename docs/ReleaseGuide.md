## Guide to release new version of matlab-bindings
The developer who is releasing a new version of the matlab-bindings is expected to follow this work flow:

The release of the `matlab-bindings` repository is made from a release branch called `matlab-bindings-v2.1.1.1`. This branch is mainly needed to help other developers with testing.

1. Create a branch called `matlab-bindings-v2.1.1.1` from the latest commit of `develop`.

2. [Open a Pull Request `master` <-- `matlab-bindings-v2.1.1.1`](https://github.com/precice/matlab-bindings/compare/master...master) named after the version (i.e. `Release v2.1.1.1`) and briefly describe the new features of the release in the PR description.

3. Bump the version in the following places:

    * `Contents.m` on `matlab-bindings-v2.1.1.1`.

4. [Draft a New Release](https://github.com/precice/matlab-bindings/releases/new) in the `Releases` section of the repository page in a web browser. The release tag needs to be the exact version number (i.e.`v2.1.1.1` or `v2.1.1.1rc1`, compare to [existing tags](https://github.com/precice/python-bindings/tags)). Use `@target:master`. Release title is also the version number (i.e. `v2.1.1.1` or `v2.1.1.1rc1`, compare to [existing releases](https://github.com/precice/matlab-bindings/tags)). 

    * *Note:* If it is a pre-release then the option *This is a pre-release* needs to be selected at the bottom of the page. Use `@target:matlab-bindings-v2.1.1.1` for a pre-release, since we will never merge a pre-release into master.

    a) If a pre-release is made: Directly hit the "Publish release" button in your Release Draft.

    b) If this is a "real" release: As soon as one approving review is made, merge the release PR (from `matlab-bindings-v2.1.1.1`) into `master`.

6. Merge `master` into `develop` for synchronization of `develop`.

7. If everything is in order up to this point then the new version can be released by hitting the "Publish release" button in your Release Draft. This will create the corresponding tag.
