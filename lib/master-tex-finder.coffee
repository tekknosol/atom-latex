fs = require "fs"
path = require "path"
MagicParser = require "./parsers/magic-parser"

# MasterTexFinder is a utility class returning the master tex file
# in a latex project. The algorithm always returns a result unless
# the directory does not include any tex file. The result is guaranteed
# to be the latex master file if the project is correctly structured (i.e.,
# inclusion graph is a tree).

module.exports =
class MasterTexFinder
  # Create a new MasterTexFinder.
  # @param filePath: a file name in the directory to be searched
  constructor: (filePath) ->
    @filePath = filePath
    @projectPath = path.dirname(@filePath)

  # Returns the list of tex files in the project directory
  getTexFilesList: ->
    fs.readdirSync(@projectPath).filter (name) ->
      name.match /\.tex$/

  # Returns true if fname is not a valid file name, returns false otherwise
  isInvalidFilePath: ->
    return !fs.existsSync(@filePath)

  # Returns true iff fname is a master file (contains the documentclass declaration)
  isMasterFile: (fname) ->
    fs.readFileSync(fname).toString().match(/(^\s*|\n\s*)\\documentclass(\[.*\])?\{.*\}/) != null

  # Returns an array containing the path to the root file indicated by a magic
  # comment in @filePath.
  # Returns null if no magic comment can be found in @filePath.
  getMagicCommentMasterFile: ->
    {root} = new MagicParser(@filePath).parse()
    return null unless root?

    path.join(@projectPath, root)

  # Returns the list of tex files in the directory where @filePath lives that
  # contain a documentclass declaration.
  getHeuristicSearchMasterFile: ->
    files = @getTexFilesList()
    return @filePath if files.length == 0
    return files[0] if files.length == 1

    result = []
    for masterCandidate in files
      if @isMasterFile(path.join(@projectPath, masterCandidate))
        result.push(path.join(@projectPath, masterCandidate))

    if result.length == 1
      return result[0]

    console.warn "Cannot find latex master file" unless atom.inSpecMode()
    @filePath

  # Returns the a latex master file.
  #
  # If no latex master file can be found or if @filePath is an invalid file name returns @filePath
  # If the @filePath is itself a master file, it returns immediately
  # If @filePath contains a magic comment uses that comment to find determine the master file
  # Otherwise it searches the directory where @filePath is contained for files
  # having a "documentclass" declaration.
  getMasterTexPath: ->
    @isInvalidFilePath() && @filePath ||
    @isMasterFile(@filePath) && @filePath ||
    @getMagicCommentMasterFile() ||
    @getHeuristicSearchMasterFile()