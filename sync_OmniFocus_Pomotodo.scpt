property folder_name : "Work"
property flagged_needed : true
property tag_filter : missing value
property token : "token"

set candidate_tasks to get_omnifocus_tasks(folder_name, flagged_needed, tag_filter)

set mapping to {}
repeat with anOmniFocusTask in candidate_tasks
	set uuid to add_pomotodo_task(anOmniFocusTask)
	set mapping to mapping & {{key:uuid, value:id of anOmniFocusTask}}
end repeat

on add_pomotodo_task(omnifocus_task)
	log "Adding task '" & name of omnifocus_task & "' to Pomotodos"
	set uuid to ""
	set postCommand to "curl --request 'POST' --header 'Authorization: token " & token & "' --header 'Content-Type: application/json' --data '{\"description\": \"" & name of omnifocus_task & "\"}' https://api.pomotodo.com/1/todos"
	set postResponse to do shell script postCommand
	tell application "JSON Helper"
		set taskCreated to (read JSON from postResponse)
		set uuid to uuid of taskCreated
	end tell
	return uuid
end add_pomotodo_task

on get_todos(completed_needed)
	set todos to {}
	set getCommand to "curl --request 'GET' --header 'Authorization: token " & token & "' https://api.pomotodo.com/1/todos?completed=" & completed_needed
	set getResponse to do shell script getCommand
	set srcJson to getResponse
	tell application "JSON Helper"
		set todos to todos & (read JSON from srcJson)
	end tell
	return todos
end get_todos

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
