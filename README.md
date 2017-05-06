# Neph

A modern command line job processor written in Crystal that can execute jobs concurrently. :rocket:  
Neph can be substitute for `make` command. :rocket:

![neph](https://raw.githubusercontent.com/tbrand/neph/master/img/neph.gif)  

Neph is self-hosting. So after installing neph, try
```bash
> neph
```
at installed directory.

## Installation

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
    invalid_command
  ignore_error:
    true
```
In this jobs, hello job will raise an error since `invalid_command` command doesn't exist. But main job will be triggered by ignoring the error.

You can specify sources by `sources:` for the jobs like `make` command.
```yaml
main:
  command:
    echo "Main!"
  depends_on:
    - hello
  sources:
    - src/test.c
hello:
  command:
    invalid_command
  ignore_error:
    true
```
If the sources are not updated, the job will be skipped.

See [sample](https://github.com/tbrand/neph/blob/master/sample/neph.yml) for details.

## Used

Neph is used in [which_is_the_fastest](https://github.com/tbrand/which_is_the_fastest). In `which_is_the_fastest`, building time is **reduced from 102[sec] to 33[sec]**. [neph.yml](https://github.com/tbrand/which_is_the_fastest/blob/master/neph.yml) is here.

## TODO
 - [ ] Add specs
 - [ ] Set log types

## Contributing

1. Fork it ( https://github.com/tbrand/neph/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [tbrand](https://github.com/tbrand) Taichiro Suzuki - creator, maintainer
