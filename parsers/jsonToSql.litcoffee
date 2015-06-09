# CHTN Vocabulary JSON to SQL Parser

Parses the JSON representation of the CHTN Vocabulary to SQL.

# 0) Setup

    schemaFile  = "#{__dirname}/../static/chtnVocabularySchema.sql" # location relative to where the process is run
    packageInfo = require "../package.json"         # location relative to where this file lives

    module.exports = (vocabularyJson, callback) ->
        sqlString      = "# CHTN Vocab-Disease List SQL Representation\n"
        sqlString     += "# See #{packageInfo.homepage}\n\n"
        knownEntities  = {}
        knownSubsites  = {}
        knownModifiers = {}


# 1) Schema
Read the schema file and add to the `sqlString`

        fs = require "fs"
        schema = fs.readFileSync schemaFile, encoding: "utf8"
        sqlString += schema + "\n\n"

# 2) Data
We'll parse each row into however many rows we need.


## 2-a) Creating the relationship functions
Each relationship function creates the appropriate sql string, given the row,
for it's relationship type (master, site-subsite, diagnosis-modifier).

        generateMasterRelationshipString = (row) ->
            id    = row['Id']
            catId = row['Category Id']              or "C0" # If no value is given for a field, it becomes "ANY".
            asId  = row['Anatomic Site Id']         or "S0"
            ssId  = row['Subsite Id']               or "SS0"
            dxId  = row['Diagnosis Id']             or "D0"
            dxmId = row['Diagnosis Modifier Id']    or "DM0"
            "INSERT INTO dis_relationship_master VALUES ('#{id}', '#{catId}', '#{asId}', '#{ssId}', '#{dxId}', '#{dxmId}');\n"

        generateSiteSubsiteRelationshipString = (row) ->
            if row['Anatomic Site Id'] and row['Subsite Id'] # Only create site/subsite relationships if both exist.
                subsiteStatement = 'INSERT INTO dis_relationship_site_to_subsite VALUES (\'' + row['Anatomic Site Id'] + '\', \'' + row['Subsite Id'] + '\');\n'
                if not knownSubsites[subsiteStatement]
                    knownSubsites[subsiteStatement] = true
                    return subsiteStatement
                else return ""
            else return ""

        generateDiagnosisModifierRelationshipString = (row) ->
            if row['Diagnosis Id'] and row['Diagnosis Modifier Id'] # Only create relationships if both exist.
                subsiteStatement = 'INSERT INTO dis_relationship_diagnosis_to_diagnosis_modifier VALUES (\'' + row['Diagnosis Id'] + '\', \'' + row['Diagnosis Modifier Id'] + '\');\n'
                if not knownModifiers[subsiteStatement]
                    knownModifiers[subsiteStatement] = true
                    return subsiteStatement
                else return ""
            else return ""

                    

## 2-b) Creating the row parsing function
The row parsing function `parseRow` takes a row and appends the appropriate
lines to `sqlString` to ensure all entities are represented (once each) in their
respective data tables, and that any relationships represented by the row are
likewise in their respective relationship tables.

        parseRow = (row) ->
            insertStatement = ""

            if not knownEntities[row['Anatomic Site Id']]
                insertStatement += 'INSERT INTO anatomic_sites VALUES (\'' + row['Anatomic Site Id'] + '\', \'' + row['Anatomic Site'] + '\');\n'
                knownEntities[row['Anatomic Site Id']] = true

            if not knownEntities[row['Subsite Id']]
                insertStatement += 'INSERT INTO subsites VALUES (\'' + row['Subsite Id'] + '\', \'' + row['Subsite'] + '\');\n'
                knownEntities[row['Subsite Id']] = true

            if not knownEntities[row['Category Id']]
                insertStatement += 'INSERT INTO categories VALUES (\'' + row['Category Id'] + '\', \'' + row['Category'] + '\');\n'
                knownEntities[row['Category Id']] = true

            if not knownEntities[row['Diagnosis Id']]
                insertStatement += 'INSERT INTO diagnoses VALUES (\'' + row['Diagnosis Id'] + '\', \'' + row['Diagnosis'] + '\');\n'
                knownEntities[row['Diagnosis Id']] = true

            if row['Diagnosis Modifier Id'] and not knownEntities[row['Diagnosis Modifier Id']]
                insertStatement += 'INSERT INTO diagnosis_modifiers VALUES (\'' + row['Diagnosis Modifier Id'] + '\', \'' + row['Diagnosis Modifier'] + '\');\n'
                knownEntities[row['Diagnosis Modifier Id']] = true

            insertStatement += generateMasterRelationshipString row
            insertStatement += generateSiteSubsiteRelationshipString row
            insertStatement += generateDiagnosisModifierRelationshipString row
            sqlString += insertStatement

## 2-c) Run the row parsing function on all rows

        parseRow row for row in vocabularyJson

# 3) Return the SQL Represetation
We `callback` with `null` as the first argument since there was no error.

        callback null, sqlString
