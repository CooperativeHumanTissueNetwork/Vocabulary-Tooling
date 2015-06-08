# CHTN Modifier Vocabulary JSON to SQL Parser

Parses the JSON representation of a CHTN Modifier Vocabulary to SQL.

# 0) Setup


## 0-a) Helpers
We import and configure a few helpers to aid in string processing.

    _ = require "underscore"    # General utilities http://underscorejs.org/
    i = (require "i")(true)     # String processing https://www.npmjs.com/package/i
    tableize = (term) -> term.replace(/\s/g,"_").tableize
    slugify = (term) -> term.replace(/\s/g,"_").toLowerCase()

## 0-b) Module Setup
The JSON to SQL parser is provided as a [node module](https://nodejs.org/api/modules.html)

    schemaFile  = "static/chtnVocabularySchema.sql" # location relative to where the process is run
    packageInfo = require "../package.json"         # location relative to where this file lives
    module.exports = (vocabularyJson, callback) ->
        sqlString      = "# Generated by CHTN Modifier Vocabulary JSON to SQL Parser\n"
        knownEntities  = {}

# 1) Schema
The schema comprises a single master relationship table and an individual data
table for each entity type represented.

        wellKnownEntites = _.pluck(_.values(require "../static/chtnVocabularyEntities.json"), "description")
        schema = ""

## 1-a) Data Tables

        descriptions = Object.keys(vocabularyJson[0]).filter (key) -> !key.match /Id/
        descriptions.forEach (description) ->
            if not _.contains wellKnownEntites, description
                schema += "CREATE TABLE #{tableize(description)} (id VARCHAR(36) PRIMARY KEY, description VARCHAR(256));\n"
        schema += "\n"

## 1-b) Relationship Table

        ids = Object.keys(vocabularyJson[0]).filter((key) -> key.match /Id/).slice(1)
        relationshipTableName = slugify(descriptions.join(" to "))
        relationshipTableString = "CREATE TABLE #{relationshipTableName} (\n    id    VARCHAR(36) PRIMARY KEY,\n"
        ids.forEach (id) ->
            relationshipTableString += "    #{slugify(id)}    VARCHAR(36),\n"
        relationshipTableString += ")\n"
        schema += relationshipTableString

## 1-c) Add the Schema to the SQL String

        sqlString += schema + "\n## End of Schema ##\n"

# 2) Data
We'll parse each row into however many rows we need.

## 2-a) Create the Entity Extraction and Relationship Functions

        knownEntities = {}
        entityExtractionFunctions = []

        descriptions.forEach (description) ->
            if not _.contains wellKnownEntites, description
                entityExtractionFunctions.push (row) ->
                    if not knownEntities[row[description]]
                        knownEntities[row[description]] = true
                        return "INSERT INTO #{tableize(description)} (id, description) VALUES ('#{row[description + " Id"]}', '#{row[description]}')\n"
                    else
                        return ""

        columnNames = "id, #{ids.map(slugify).join(", ")}"
        relationshipFunction = (row) ->
            rowData = ids.map((id) -> ", '#{row[id]}'").join("")
            "INSERT INTO #{relationshipTableName} (#{columnNames}) VALUES ('#{row.Id}'#{rowData})\n"

## 2-b) Creating the row parsing function
The row parsing function `parseRow` takes a row and appends the appropriate
lines to `sqlString` to ensure all entities are represented (once each) in their
respective data tables, and that any relationships represented by the row are
likewise in their respective relationship tables.

        parseRow = (row) ->
            insertStatement = ""
            entityExtractionFunctions.forEach (entityExtractionFunction) ->
                insertStatement += entityExtractionFunction row
            insertStatement += relationshipFunction row
            sqlString += insertStatement

## 2-c) Run the row parsing function on all rows

        parseRow row for row in vocabularyJson

# 3) Return the SQL Represetation
We `callback` with `null` as the first argument since there was no error.

        callback null, sqlString
