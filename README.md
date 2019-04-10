# OmniFocus x Pomotodo
## Installation
1. Make sure you have a [Pomotodo](https://pomotodo.com/app/) account and apply for a developer account [here](https://pomotodo.com/developer). Note down your **Personal Access Token**.
2. Configure ``sync_OmniFocus_Pomotodo.scpt``. Configure:
    1. ``folder_name``: if you want to monitor a particular OmniFocus folder
    2. ``flagged_needed``: ``ture`` or ``false``, to configure if you want to monitor for flagged OmniFocus tasks only
    3. ``tag_filter``: **one** tag to use when filtering OmniFocus tasks
    4. ``"token"``: replace it with your **Personal Access Token** from Pomotodo
    5. ``look_back_days``: number of days to look back for Pomotodo.
3. Edit ``OmniFocus_Pomotodo.plist`` to put in the path to ``sync_OmniFocus_Pomotodo.scpt``. You can also configure ``StartInterval`` to control the frequency of the sync script
4. In your terminal, enter ``launchctl load [path to OmniFocus_Pomotodo.plist]`` to start the sync process. ``launchctl unload [path to OmniFocus_Pomotodo.plist]`` to stop the sync process.
