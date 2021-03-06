# CHTN Vocabulary Builder

Builds JSON, JSON-LD, and SQL representations of the CHTN Vocabulary from the tabular version.

## 0) Parse Command Line Arguments
Parse the command line arguments using [yargs].

    argv = require "yargs"
        .usage "Usage: npm run-script build -- -f <vocabulary file> [-m]"
        .alias "f", "file"
        .describe "f", "Vocabulary File to Process"
        .demand "f"
        .boolean "m"
        .alias "m", "modifier"
        .describe "m", "Vocabulary File is a Modifier Vocabulary"
        .help "h"
        .alias "h", "help"
        .argv

    # Extract the directory and filename
    path = require "path"
    workingDirectory = path.resolve path.dirname argv.file #argv.directory
    tabularFileName  = path.basename argv.file

    # Extract the vocabulary name and create the filenames for the alternative representations.
    vocabularyName   = tabularFileName.split(".").slice(0,-1).join(".")
    jsonFileName     = "#{vocabularyName}.json"
    sqlFileName      = "#{vocabularyName}.sql"
    jsonldFileName   = "#{vocabularyName}.jsonld"
    ntriplesFileName = "#{vocabularyName}.nt"

    console.log "Parsing file #{tabularFileName} in directory #{workingDirectory}"
    console.log "Generating #{jsonFileName}, #{sqlFileName}, #{jsonldFileName}, and #{ntriplesFileName}."

## 1) Read in the raw file.
Read in the Tab-Separated version of the vocabulary using [readFileSync][].

    fs = require "fs"
    vocabularyCsv = fs.readFileSync "#{workingDirectory}/#{tabularFileName}", encoding: "utf8"

## 2) Parse JSON
Parse a JSON representation of the vocabulary from the tab-separated version
using [d3's][d3] built-in [CSV parser][d3-csv]. We use [d3][] to reduce the
number of dependencies; we'll also use it to generate images later.

    Baby = require "babyparse"
    parseResults = Baby.parse vocabularyCsv, { header: true, delimiter: "\t" }
    vocabularyJson = parseResults.data
    console.log "Parsed #{tabularFileName} in to #{vocabularyJson.length} rows."


### 2-a) Generate any necessary Id's for Modifier
Each column is either an Id column (e.g. "Anatomic Site Id") or a Description
column ("Anatomic Site"). This script assumes that Id columns have the name
of their corresponding description with the suffix " Id". If no such column is
found, the Id's are generated here.

    if argv.m
        _ = require "underscore"
        keys = Object.keys vocabularyJson[0]
        ids = keys.filter (key) -> key.match /Id/
        descriptions = keys.filter (key) -> !key.match /Id/
        descriptionsWithoutIds = descriptions.filter (description) -> ! _.contains ids, "#{description} Id"

        console.log "Generating Id's for #{descriptionsWithoutIds.join(", ")}"

        indices = {}
        slugify = (term) -> term.replace(/\W/g,"").toLowerCase()
        vocabularyJson.forEach (row) ->
            descriptionsWithoutIds.forEach (description) ->
                if not indices[description] then indices[description] = {}
                if not indices[description][row[description]] then indices[description][row[description]] = "#{slugify(description)}#{Object.keys(indices[description]).length+1}"
                row[description + " Id"] = indices[description][row[description]]


### 2-b) Save the Parsed JSON
We'll save the stringified JSON, pretty-printed with a tab-width of 2.

    jsonString = JSON.stringify vocabularyJson, null, 2
    fs.writeFile "#{workingDirectory}/#{jsonFileName}", jsonString, (err) ->
        if err then throw err else console.log "Saved #{jsonFileName}"

## 3) Parse SQL
The SQL representation is parsed from the JSON representation.

    if argv.m then jsonToSql = require "./parsers/jsonToModifierSql" else jsonToSql = require "./parsers/jsonToSql"
    jsonToSql vocabularyJson, (err, vocabularySql) ->
        if err then throw err
        fs.writeFile "#{workingDirectory}/#{sqlFileName}", vocabularySql, (err) ->
            if err then throw err else console.log "Saved #{sqlFileName}"

## 4) Parse JSON-LD and N-Triples
The [JSON-LD][] representation is parsed from the JSON representation, then the
[N-Triples][] representation is parsed from the [JSON-LD][] representation.

    if not argv.m
        jsonToJsonld = require "./parsers/jsonToJsonld"
        jsonld = require "jsonld"
        jsonToJsonld vocabularyJson, (err, vocabularyJsonld) ->
            if err then throw err

            jsonldString = JSON.stringify vocabularyJsonld, null, 2
            fs.writeFile "#{workingDirectory}/#{jsonldFileName}", jsonldString, (err) ->
                if err then throw err else console.log "Saved #{jsonldFileName}"

            jsonld.normalize vocabularyJsonld, format: "application/nquads", (err, result) ->
                if err then throw err
                vocabularyNTriples = result
                fs.writeFile "#{workingDirectory}/#{ntriplesFileName}", vocabularyNTriples, (err) ->
                    if err then throw err else console.log "Saved #{ntriplesFileName}"


[readFileSync]: http://nodejs.org/api/fs.html#fs_fs_readfilesync_filename_options "fs.readFileSync documentation"
[d3]: http://d3js.org/ "d3js homepage"
[d3-csv]: https://github.com/mbostock/d3/wiki/CSV "d3.csv documentation"
[JSON-LD]: http://json-ld.org/ "JSON-LD homepage"
[N-Triples]: http://www.w3.org/TR/n-triples/ "N-Triples Recommendation"
[yargs]: https://github.com/bcoe/yargs "yargs Documentation"
