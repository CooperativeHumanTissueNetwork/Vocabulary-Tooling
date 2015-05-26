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

    d3 = require "d3"
    vocabularyJson = d3.tsv.parse vocabularyCsv
    console.log "Parsed #{tabularFileName} in to #{vocabularyJson.length} rows."

### 2-a) Split Diagnosis Modifiers from Diagnoses
This will also require generating a new Diagnosis and Diagnosis Modifier ID,
since the build in `D1234` ID is for the Diagnosis + Modifier combo. These
ID's are generated sequentially, starting at D1 and DM1

    diagnoses           = {} #Index of diagnoses
    diagnosisModifiers  = {} #Index of diagnosis modifiers
    vocabularyJson.forEach (row) ->
        if not row["Diagnosis"] then return
        # Split diagnosis and modifier
        [diagnosis, modifier]     = row["Diagnosis"].split(" \\ ")

        # Save combined diagnosis and id
        row["Combined Diagnosis"] = row["Diagnosis"]
        row["Combined DX Id"]     = "C#{row["DX Id"]}"

        # Index and save diagnosis and diagnosis ID
        if not diagnoses[diagnosis] then diagnoses[diagnosis] = "D#{Object.keys(diagnoses).length+1}"
        row["DX Id"]     = diagnoses[diagnosis]
        row["Diagnosis"] = diagnosis

        # Index and save modifier and modifier ID
        if not diagnosisModifiers[modifier] then diagnosisModifiers[modifier] = "DM#{Object.keys(diagnosisModifiers).length+1}"
        row["DXM Id"]     = diagnosisModifiers[modifier]
        row["Diagnosis Modifier"] = modifier or ""



### 2-b) Save the Parsed JSON
We'll save the stringified JSON, pretty-printed with a tab-width of 2.
    
    jsonString = JSON.stringify vocabularyJson, null, 2
    fs.writeFile "#{workingDirectory}/#{jsonFileName}", jsonString, (err) ->
        if err then throw err else console.log "Saved #{jsonFileName}"

## 3) Parse SQL
The SQL representation is parsed from the JSON representation.

    jsonToSql = require "./parsers/jsonToSql"
    jsonToSql vocabularyJson, (err, vocabularySql) ->
        if err then throw err
        fs.writeFile "#{workingDirectory}/#{sqlFileName}", vocabularySql, (err) ->
            if err then throw err else console.log "Saved #{sqlFileName}"

## 4) Parse JSON-LD and N-Triples
The [JSON-LD][] representation is parsed from the JSON representation, then the 
[N-Triples][] representation is parsed from the [JSON-LD][] representation.

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