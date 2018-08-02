<h1 align="center">
	<img src="https://cloud.githubusercontent.com/assets/3483230/25774528/7bb488c4-32cb-11e7-9937-5ce61caea177.png" width="180" />  
</h1>

<p align="center">
	<a href="https://travis-ci.org/tbrand/neph"><img src="https://travis-ci.org/tbrand/neph.svg?branch=master&style=flat" alt="Latest version" /></a>
	<a href="https://github.com/tbrand/neph/releases"><img src="https://img.shields.io/github/release/tbrand/neph.svg?style=flat" alt="Latest version" /></a>
	<a href="https://raw.githubusercontent.com/tbrand/neph/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat" /></a>
	<a href="https://github.com/tbrand/neph/wiki"><img src="https://img.shields.io/badge/Document-wiki-blue.svg?style=flat" /></a>
	<a href="https://github.com/tbrand/neph/issues"><img src="https://img.shields.io/github/issues/tbrand/neph.svg?style=flat" /></a>
</p>

<p align="center">
	<img src="https://user-images.githubusercontent.com/3483230/43591914-5c068eca-96af-11e8-9164-8df794ca0436.gif" width="700" />
</p>

- A modern command line job processor written in Crystal :rocket:
- Can execute jobs concurrently. :rocket:
- Can be substitute for `make` command. :rocket:

## Installation

### Arch Linux
Use your favourite AUR helper.  
Package name: [`neph-git`](https://aur.archlinux.org/packages/neph-git/)

### Mac
You can install Neph with `brew`.
```bash
$ brew tap tbrand/homebrew-neph
$ brew install neph
```

### Manual
Build dependencies:
- `crystal` and `shards` for building the binary
- `go-md2man` for generating the man page

It needs `libyaml` to be installed.

If you have a previous version of `neph` installed:
```bash
$ git clone https://github.com/tbrand/neph
$ cd neph
$ neph           # man page will be at neph.1, binary will be at bin/neph
```
If you don't have a previous version of `neph` installed:
```bash
$ git clone https://github.com/tbrand/neph
$ cd neph
$ shards build    # Now executable binary is located at bin/neph
$ bin/neph man    # Generate man page. It will be located at neph.1
```

## Usage

All features for neph.yaml is written in [sample/neph.yaml](https://github.com/tbrand/neph/blob/master/sample/neph.yaml). So please refer for the details.

Wiki is also maintained as a document. Here is a full features.
 - [Execute command from neph](https://github.com/tbrand/neph/wiki/Execute-command-from-neph)
 - [Define dependencies between jobs](https://github.com/tbrand/neph/wiki/Define-dependencies-between-jobs)
 - [Working directory](https://github.com/tbrand/neph/wiki/Working-directory)
 - [Specify sources](https://github.com/tbrand/neph/wiki/Specify-sources)
 - [Ignoring errors](https://github.com/tbrand/neph/wiki/Ignoring-errors)
 - [Hide executing command](https://github.com/tbrand/neph/wiki/Hide-executing-command)
 - [Set a job result to env vars](https://github.com/tbrand/neph/wiki/Set-a-job-result-to-env-vars)
 - [Import other configurations](https://github.com/tbrand/neph/wiki/Import-other-configurations)
 - [Command line options](https://github.com/tbrand/neph/wiki/Command-line-options)
 - [Log locations](https://github.com/tbrand/neph/wiki/Log-locations)
 - [Log modes](https://github.com/tbrand/neph/wiki/Log-modes)

## Use cases

Neph is used in [which_is_the_fastest](https://github.com/tbrand/which_is_the_fastest).  
The build time is **reduced from 102[sec] to 33[sec]**.  
The [neph.yaml](https://github.com/tbrand/which_is_the_fastest/blob/master/neph.yaml) is here.

## Contributing

1. Fork it ( https://github.com/tbrand/neph/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [tbrand](https://github.com/tbrand) Taichiro Suzuki - creator, maintainer
- [notramo](https://github.com/notramo) Márton Szabó - maintainer
