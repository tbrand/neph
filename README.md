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


- A modern command line job processor :rocket:
- Can execute jobs concurrently. :rocket:
- Alternative to `make` :rocket:

## Installation

#### Arch Linux
Available in the AUR: [`neph-git`](https://aur.archlinux.org/packages/neph-git/)

#### Mac
You can install Neph with `brew`.
```bash
$ brew tap tbrand/homebrew-neph
$ brew install neph
```

#### Manual
Build dependencies:
- `crystal` and `shards` for building the binary
- [`go-md2man`](https://github.com/cpuguy83/go-md2man) for generating the man page

It needs `libyaml` to be installed.

```bash
$ git clone https://github.com/tbrand/neph
$ cd neph
$ shards build    # Now executable binary is located at bin/neph
$ bin/neph man    # Generate man page. It will be located at neph.1
```

## Usage

See the example build file: [`example/neph.yaml`](https://github.com/tbrand/neph/blob/master/example/neph.yaml)

## Contributing
#### **You can contribute even if you don't know Crystal. How?**
  - You can learn Crystal. It's a very good language. https://crystal-lang.org/
  - Contribute to [`go-md2man`](https://github.com/cpuguy83/go-md2man) (written in Go), which is used to generate the man page.
  - Contribute to the tools that we use in development of Neph:  
     
     |project                                                              |lang  |
     |:--------------------------------------------------------------------|:-----|
     |[Kakoune](http://kakoune.org), a very good editor                    |C++   |
     |[Elvish](https://elv.sh), a modern and user friendly shell           |Go    |
     |[slit](https://github.com/tigrawap/slit), a modern pager             |Go    |
     |[exa](https://the.exa.website/), a modern replacement for `ls`       |Rust  |
     |[fd](https://github.com/sharkdp/fd), a modern replaement for `find`  |Rust  |

#### **If you know Crystal**

**Pull requests are welcome.**  
**Please set up the `pre-commit` Git hook before starting:**
```bash
ln -s ../../pre-commit .git/hooks/pre-commit
```

## Use cases

Neph is used in [which_is_the_fastest](https://github.com/tbrand/which_is_the_fastest).  
The build time is **reduced from 102[sec] to 33[sec]**.  
The [neph.yaml](https://github.com/tbrand/which_is_the_fastest/blob/master/neph.yaml) is here.

## Contributors

- [tbrand](https://github.com/tbrand) Taichiro Suzuki - creator, maintainer
- [notramo](https://github.com/notramo) Márton Szabó - maintainer
