<h1 align="center">
	<img src="https://cloud.githubusercontent.com/assets/3483230/25774528/7bb488c4-32cb-11e7-9937-5ce61caea177.png" width="180" />  
</h1>

<p align="center">
	<a href="https://travis-ci.org/tbrand/neph"><img src="https://travis-ci.org/tbrand/neph.svg?branch=master?style=flat" alt="Latest version" /></a>
	<a href="https://github.com/tbrand/neph/releases"><img src="https://img.shields.io/github/release/tbrand/neph.svg?style=flat" alt="Latest version" /></a>
	<a href="https://raw.githubusercontent.com/tbrand/neph/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat" /></a>
	<a href="https://github.com/tbrand/neph/wiki"><img src="https://img.shields.io/badge/Document-wiki-blue.svg?style=flat" /></a>
	<a href="https://github.com/tbrand/neph/issues"><img src="https://img.shields.io/github/issues/tbrand/neph.svg?style=flat" /></a>
</p>

A modern command line job processor written in Crystal that can execute jobs concurrently. :rocket:  
Neph can be substitute for `make` command. :rocket:  

<img src="https://raw.githubusercontent.com/tbrand/neph/master/img/neph.gif" width="600" />  

## Installation

Neph is written in Crystal, so you need Crystal to install Neph. To install Crystal, see [official manual](https://github.com/crystal-lang/crystal).

To install neph, run following command
```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/master/tools/install.rb)"
```

## Usage

All features for neph.yml is written in [sample/neph.yml](https://github.com/tbrand/neph/blob/master/sample/neph.yml). So please refer for the details.

Wiki is also maintained as a document. Here is a full features.
 - [Execute command from neph](https://github.com/tbrand/neph/wiki/Execute-command-from-neph)
 - [Define dependencies between jobs](https://github.com/tbrand/neph/wiki/Define-dependencies-between-jobs)
 - [Working directory](https://github.com/tbrand/neph/wiki/Working-directory)
 - [Specify sources](https://github.com/tbrand/neph/wiki/Specify-sources)
 - [Ignoring errors](https://github.com/tbrand/neph/wiki/Ignoring-errors)
 - [Import other configurations](https://github.com/tbrand/neph/wiki/Import-other-configurations)
 - [Command line options](https://github.com/tbrand/neph/wiki/Command-line-options)
 - [Log locations](https://github.com/tbrand/neph/wiki/Log-locations)

## Use cases

Neph is used in [which_is_the_fastest](https://github.com/tbrand/which_is_the_fastest). In `which_is_the_fastest`, building time is **reduced from 102[sec] to 33[sec]**. [neph.yml](https://github.com/tbrand/which_is_the_fastest/blob/master/neph.yml) is here.

## Contributing

1. Fork it ( https://github.com/tbrand/neph/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [tbrand](https://github.com/tbrand) Taichiro Suzuki - creator, maintainer
