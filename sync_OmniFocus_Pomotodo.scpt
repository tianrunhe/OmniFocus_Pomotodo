property folder_name : missing value
property flagged_needed : true
property tag_filter : missing value
property token : "token"
property look_back_days : 7

set candidate_tasks to get_omnifocus_tasks(folder_name, flagged_needed, tag_filter)
set completed_later_than_date to do shell script "date -v-" & look_back_days & "d '+%Y-%m-%d'"
set todos to get_todos(missing value) & get_todos(completed_later_than_date)

-- create mapping between Pomotodo todo uuid -> OmniFocus task id
set mapping to {}
repeat with todo in todos
	set uuid to uuid of todo
	set splitStrings to my theSplit(|description| of todo, "|")
	if (count of splitStrings) = 2 then
		set omniFocus_id to last item of splitStrings
		set mapping to mapping & {{key:uuid, value:omniFocus_id, completed:completed of todo, name:|description| of todo}}
	end if
end repeat

-- Iterate through OmniFocus task list, add new task to Pomotodo or mark task completed if it's completed in Pomotodo
repeat with anOmniFocusTask in candidate_tasks
	set omniFocus_id to id of anOmniFocusTask

	set foundTask to false
	set completed to false
	set uuid to ""
	set todoName to ""
	repeat with aMapping in mapping
		if value of aMapping = omniFocus_id then
			set foundTask to true
			set completed to completed of aMapping
			set uuid to key of aMapping
			set todoName to first item of theSplit(name of aMapping, " #")
		end if
	end repeat

	if not foundTask then -- new task in OmniFocus, need to add to Pomotodo
		add_pomotodo_task(anOmniFocusTask)
	else -- task is already synced to Pomotodo
		if completed then
			mark_task_completed(anOmniFocusTask, folder_name)
		else
			if name of anOmniFocusTask is not equal to todoName then
				display alert "Name of the task has changed from " & todoName & " to " & name of anOmniFocusTask
				delete_todo(uuid)
				add_pomotodo_task(anOmniFocusTask)
			end if
		end if
	end if

end repeat

repeat with aMapping in mapping
	if completed of aMapping is false and is_task_flagged(value of aMapping, folder_name) is false then
		display alert "OmniFocus task " & name of aMapping & " is no longer flagged in OmniFocus, going to delete it from Pomotodo"
		delete_todo(key of aMapping)
	end if
end repeat

on add_pomotodo_task(omnifocus_task)
	log "Adding task '" & name of omnifocus_task & "' to Pomotodos"
	set uuid to ""
	set postCommand to "curl --request 'POST' --header 'Authorization: token " & token & "' --header 'Content-Type: application/json' --data '{\"description\": \"" & construct_todo_description(omnifocus_task, folder_name) & "\"}' https://api.pomotodo.com/1/todos"
	set postResponse to do shell script postCommand
	tell application "JSON Helper"
		set taskCreated to (read JSON from postResponse)
		set uuid to uuid of taskCreated
	end tell
	return uuid
end add_pomotodo_task

on construct_todo_description(omnifocus_task, folder_name)
	tell application "OmniFocus"
		tell default document
			if folder_name is missing value then
				set projectList to flattened projects
			else
				set projectList to flattened projects of folder named folder_name
			end if
			repeat with aProject in projectList
				set taskList to (flattened tasks of aProject whose completed is false)
				repeat with aTask in taskList
					if id of omnifocus_task = id of aTask then
						set rootFolderName to folder of aProject

						if rootFolderName is missing value then --- checking for root level projects
							set rootFolderName to "n/a"
							set foundRootFolderName to true
						else
							set foundRootFolderName to false
						end if

						repeat until foundRootFolderName is true
							set upperFolder to container of rootFolderName
							if name of upperFolder is equal to "OmniFocus" then
								set rootFolderName to name of rootFolderName as string
								set foundRootFolderName to true
							else
								set rootFolderName to upperFolder
							end if
						end repeat

						set todo_description to name of omnifocus_task & " #" & rootFolderName & " |" & id of omnifocus_task
					end if
				end repeat
			end repeat
		end tell
	end tell
	return todo_description
end construct_todo_description

on get_todos(completed_later_than_date)
	set todos to {}
	if completed_later_than_date is missing value then
		set getCommand to "curl --request 'GET' --header 'Authorization: token " & token & "' https://api.pomotodo.com/1/todos"
	else
		set getCommand to "curl --request 'GET' --header 'Authorization: token " & token & "' https://api.pomotodo.com/1/todos?completed_later_than=" & completed_later_than_date
	end if
	set getResponse to do shell script getCommand
	set srcJson to getResponse
	tell application "JSON Helper"
		set todos to todos & (read JSON from srcJson)
	end tell
	return todos
end get_todos

on delete_todo(uuid)
	set getCommand to "curl --request 'DELETE' --header 'Authorization: token " & token & "' https://api.pomotodo.com/1/todos/" & uuid
	do shell script getCommand
end delete_todo

on get_omnifocus_tasks(folder_name, flagged_needed, tag_filter)
	set returnList to {}
	tell application "OmniFocus"
		tell default document
			if folder_name is missing value then
				set projectList to flattened projects
			else
				set projectList to flattened projects of folder named folder_name
			end if
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

on theSplit(theString, theDelimiter)
	-- save delimiters to restore old settings
	set oldDelimiters to AppleScript's text item delimiters
	-- set delimiters to delimiter to be used
	set AppleScript's text item delimiters to theDelimiter
	-- create the array
	set theArray to every text item of theString
	-- restore the old setting
	set AppleScript's text item delimiters to oldDelimiters
	-- return the result
	return theArray
end theSplit

on mark_task_completed(completed_task, folder_name)
	tell application "OmniFocus"
		tell default document
			if folder_name is missing value then
				set projectList to flattened projects
			else
				set projectList to flattened projects of folder named folder_name
			end if
			repeat with aProject in projectList
				set taskList to (flattened tasks of aProject whose completed is false)
				repeat with aTask in taskList
					if id of completed_task = id of aTask then
						mark complete aTask
					end if
				end repeat
			end repeat
		end tell
	end tell
end mark_task_completed

on is_task_flagged(theTaskId, folder_name)
	tell application "OmniFocus"
		tell default document
			if folder_name is missing value then
				set projectList to flattened projects
			else
				set projectList to flattened projects of folder named folder_name
			end if
			repeat with aProject in projectList
				set taskList to (flattened tasks of aProject whose completed is false)
				repeat with aTask in taskList
					if theTaskId = id of aTask then
						return flagged of aTask
					end if
				end repeat
			end repeat
		end tell
	end tell
	return false
end is_task_flagged

on encode_char(this_char)
	set the ASCII_num to (the ASCII number this_char)
	set the hex_list to {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	set x to item ((ASCII_num div 16) + 1) of the hex_list
	set y to item ((ASCII_num mod 16) + 1) of the hex_list
	return ("%" & x & y) as string
end encode_char

on encode_text(this_text, encode_URL_A, encode_URL_B)
	set the standard_characters to "abcdefghijklmnopqrstuvwxyz0123456789"
	set the URL_A_chars to "$+!'/?;&@=#%><{}[]\"~`^\\|*"
	set the URL_B_chars to ".-_:"
	set the acceptable_characters to the standard_characters
	if encode_URL_A is false then
		set the acceptable_characters to the acceptable_characters & the URL_A_chars
	end if
	if encode_URL_B is false then
		set the acceptable_characters to the acceptable_characters & the URL_B_chars
	end if
	set the encoded_text to ""
	repeat with this_char in this_text
		if this_char is in the acceptable_characters then
			set the encoded_text to (the encoded_text & this_char)
		else
			set the encoded_text to (the encoded_text & encode_char(this_char)) as string
		end if
	end repeat
	return the encoded_text
end encode_text
