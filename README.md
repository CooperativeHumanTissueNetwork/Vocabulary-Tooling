# CHTN Vocabulary Tools

Build SQL, [JSON-LD], and other versions of the CHTN Vocabulary

## Usage

Clone this repository and the core [Vocabulary], install dependencies, and go.

```shell
$ git clone https://github.com/CooperativeHumanTissueNetwork/Vocabulary.git Vocabulary
$ git clone https://github.com/CooperativeHumanTissueNetwork/Vocabulary-Tooling.git Vocabulary-Tooling
$ cd Vocabulary-Tooling
$ npm install
$ npm run build -- -f ../Vocabulary/CHTN-Core-Vocabulary.tsv
```

Run with the `-h` flag to see additional options.

```shell
$ npm run build -- -h
```

### Continuous Integration Usage

This sample Travis-CI configuration file, taken from [Vocabulary] uses the Vocabulary Tools to build and deploy the built versions through Github Releases.

```yaml
language: node_js
sudo: false
node_js:
- '4.2.4'
before_install:
- npm install https://github.com/CooperativeHumanTissueNetwork/Vocabulary-Tooling/tarball/v1.1.1
script: ./node_modules/chtn-vocabulary-tools/node_modules/coffee-script/bin/coffee node_modules/chtn-vocabulary-tools/index.litcoffee -f CHTN-Core-Vocabulary.tsv
deploy:
  provider: releases
  skip_cleanup: true
  file: 'CHTN-Core-Vocabulary.*'
  file_glob: true
  on:
    repo: CooperativeHumanTissueNetwork/Vocabulary
    tags: true
```
## History

See CHANGELOG.md

[JSON-LD]: http://json-ld.org/ "JSON-LD Homepage"
[Vocabulary]: https://github.com/CooperativeHumanTissueNetwork/Vocabulary "CHTN Vocabulary Repo"
