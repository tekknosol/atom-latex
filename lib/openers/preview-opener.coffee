child_process = require 'child_process'
Opener = require '../opener'

module.exports =
class PreviewOpener extends Opener
  open: (filePath, callback) ->
    shouldActivate = not @shouldOpenInBackground()
    command =
      """
      osascript -e \
      "
      set theFile to POSIX file \\\"#{filePath}\\\"
      set thePath to POSIX path of (theFile as alias)
      tell application \\\"Preview\\\"
        if #{shouldActivate} then activate
        open theFile
      end tell
      "
      """
    child_process.exec command, (error, stdout, stderr) ->
      exitCode = error?.code ? 0
      callback(exitCode) if callback?
