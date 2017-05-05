# Neph

Modern command line base job processor written in Crystal.:rocket:
![neph](https://cloud.githubusercontent.com/assets/3483230/25742195/56b558c6-31c9-11e7-88d2-a8cd91558293.gif)

## Installation

Cloning this project
```bash
git clone https://github.com/tbrand/neph
```

Compile
```bash
cd neph; shards build
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
```bash
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
See [sample]() for details.

## Contributing

1. Fork it ( https://github.com/tbrand/neph/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [tbrand](https://github.com/tbrand) Taichiro Suzuki - creator, maintainer
