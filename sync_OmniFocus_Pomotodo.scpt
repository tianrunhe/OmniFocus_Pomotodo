set today_str to do shell script "date '+%Y-%m-%d'"
set getCommand to "curl --request 'GET' --header 'Authorization: token $token' https://api.pomotodo.com/1/todos\\?completed\\=true\\&completed_later_than\\=" & today_str & " > ~/null/todos.json"
do shell script getCommand
set srcJson to read POSIX file (POSIX path of (path to home folder) & "null/todos.json")
tell application "JSON Helper"
  set todos to read JSON from srcJson
end tell

set getCommand to "curl --request 'GET' --header 'Authorization: token $token' https://api.pomotodo.com/1/todos > ~/null/todos.json"
do shell script getCommand
set srcJson to read POSIX file (POSIX path of (path to home folder) & "null/todos.json")
tell application "JSON Helper"
  set todos to todos & (read JSON from srcJson)
end tell

tell application "OmniFocus"
  tell default document
    set projectList to flattened projects of folder named "Work"
    repeat with aProject in projectList
      set taskList to (flattened tasks of aProject whose completed is false)
      repeat with aTask in taskList
        set description to name of aTask
        set toAdd to true
        repeat with todo in todos
          if description of todo contains description then
            log "Found the task '" & description & "' in Pomotodo"
            set toAdd to false
            if |completed| of todo is true then
              log "task '" & description & "' is marked as completed in Pomotodo. Setting the corresponding task in OmniFocus to completed as well"
              mark complete aTask
            end if
            if flagged of aTask is false then
              set toAdd to false
              log "task '" & description & "' is no longer flagged. Deleing it from Pomodos"
              set deleteCommand to "curl --request 'DELETE' --header 'Authorization: token $token' https://api.pomotodo.com/1/todos/" & uuid of todo
              do shell script deleteCommand
            end if
          end if
        end repeat

        if toAdd and flagged of aTask is true then
          log "Adding task '" & description & "' to Pomotodos"
          set postCommand to "curl --request 'POST' --header 'Authorization: token $token' --header 'Content-Type: application/json' --data '{\"description\": \"" & description & "\"}' https://api.pomotodo.com/1/todos"
          do shell script postCommand
        end if

      end repeat
    end repeat
  end tell
end tell

on get_omnifocus_tasks(folder_name, flagged_needed, tag_filter)
  set returnList to {}
  tell application "OmniFocus"
    tell default document
      set projectList to flattened projects of folder named folder_name
      repeat with aProject in projectList
        set taskList to (flattened tasks of aProject whose completed is false)
        repeat with aTask in taskList
          set tag_matched to false
          if tag_filter is missing value then
            set tag_matched to true
          else
            set tagList to (tags of aTask)
            repeat with aTag in tagList
              set tagName to name of aTag
              if (tagName is equal to tag_filter) then
                set tag_matched to true
              end if
            end repeat
          end if

          set flag_matched to false
          if flagged_needed is true then
            set flag_matched to flagged of aTask
          else
            set flag_matched to true
          end if

          if tag_matched and flag_matched then
            set returnList to returnList & {aTask}
          end if

        end repeat
      end repeat
    end tell
  end tell
  return returnList
end get_omnifocus_tasks
