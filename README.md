<h1 align="center">
	<img src="https://cloud.githubusercontent.com/assets/3483230/25774528/7bb488c4-32cb-11e7-9937-5ce61caea177.png" width="180" />  
</h1>

<p align="center">
	<a href="https://travis-ci.org/tbrand/neph"><img src="https://travis-ci.org/tbrand/neph.svg?branch=master" alt="Latest version" /></a>
	<a href="https://github.com/tbrand/neph/releases"><img src="https://img.shields.io/github/release/tbrand/neph.svg" alt="Latest version" /></a>
</p>

A modern command line job processor written in Crystal that can execute jobs concurrently. :rocket:  
Neph can be substitute for `make` command. :rocket:  

<img src="https://raw.githubusercontent.com/tbrand/neph/master/img/neph.gif" width="400" />  

Neph is self-hosting. So after installing neph, try
```bash
> neph
```
at installed directory.

## Installation

Neph is written in Crystal, so you need Crystal to install Neph. To install Crystal, see [official manual](https://github.com/crystal-lang/crystal).

To install neph, run following command
```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/tbrand/neph/release/tools/install.rb)"
```

### Install neph manually
Cloning this project
```bash
git clone https://github.com/tbrand/neph
```

Compile
```bash
> cd neph
> shards build --release
```

Now executable binary is at `neph/bin/neph`.

## Usage

Put `neph.yml` at root of your project
```yaml
main:
  command:
    echo "Hello Neph!"
```

Execute `neph`
```bash
> neph
```

STDOUT and STDERR logs are located at `.neph/log/[job_name]/*`

### Options

You can specify job name by `-j`. In neph.yml,
```yaml
hello:
  command:
    echo "Hello!"
```
Then,
```bash
> neph -j hello
```

To see other usages, use `--help` option
```bash
> neph --help
```

### neph.yml

You can define dependencies between jobs like this
```yaml
main:
  command:
    echo "Main!"
  depends_on:
    - hello
hello:
  command:
    echo "Hello!"
```
Here `main` job depends on `hello`. So when you execute `neph`, `hello` job is triggered before the execution of the `main` job.

You can ignore errors by `ignore_error: true`
```yaml
main:
  command:
    echo "Main!"
  depends_on:
    - hello
hello:
  command:
    hogehoge
  ignore_error:
    true
```
In this jobs, hello job will raise an error since `hogehoge` command doesn't exist. But main job will be triggered.

You can specify sources by `src:` for the jobs like `make` command.
```yaml
main:
  command:
    echo "Main!"
  depends_on:
    - hello
  src:
    - src/test.c
hello:
  command:
    hogehoge
  ignore_error:
    true
```
If the sources are not updated, the job will be skipped.

You can import other configurations by
```yaml
import:
  - import_config.yml

main:
  depends_on:
    import_config_job
```
where `import_config.yml` is
```yaml
import_config_job:
  command:
    echo "OK!"
```

See [sample](https://github.com/tbrand/neph/blob/master/sample/neph.yml) for details.

## Used

Neph is used in [which_is_the_fastest](https://github.com/tbrand/which_is_the_fastest). In `which_is_the_fastest`, building time is **reduced from 102[sec] to 33[sec]**. [neph.yml](https://github.com/tbrand/which_is_the_fastest/blob/master/neph.yml) is here.

## Contributing

1. Fork it ( https://github.com/tbrand/neph/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [tbrand](https://github.com/tbrand) Taichiro Suzuki - creator, maintainer
