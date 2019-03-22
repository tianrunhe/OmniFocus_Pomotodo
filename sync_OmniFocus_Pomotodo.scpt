property folder_name : "Work"
property flagged_needed : true
property tag_filter : missing value
property token : "abc"

set candidate_tasks to get_omnifocus_tasks(folder_name, flagged_needed, tag_filter)

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
