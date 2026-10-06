<!-- TOC --><a name="taskchamp"></a>

# Taskchamp

![image](https://github.com/user-attachments/assets/9520b546-c709-4a62-bda0-e20816985e14)

Use [Taskwarrior](https://taskwarrior.org/), a simple command line interface to manage your tasks from you computer, and a beautiful native app to manage them from your phone. Create notes for your tasks with seamless [Obsidian](https://obsidian.md/) integration.

> For contributing to Taskchamp, please read the [CONTRIBUTING.md](CONTRIBUTING.md) file.

> [!IMPORTANT]
> We are looking for beta testers to help us test new builds before releasing them to the App Store, or simply if you want to test the app before buying it. For becoming a beta tester, please go to the [TestFlight page](https://testflight.apple.com/join/K4wrKrzg).

<!-- TOC start -->

- [Contributing](CONTRIBUTING.md)
- [Installation](#installation)
- [Setup with Taskwarrior](#setup-with-taskwarrior)
  - [Setup with Taskchampion Sync Server](#setup-with-taskchampion-sync-server)
  - [Setup with S3](#setup-with-s3)
  - [Setup with GCP](#setup-with-gcp)
  - [Setup with iCloud Drive](#setup-with-icloud-drive)
- [Filters](#filters)
- [vimango task notes](#vimango-task-notes)

<!-- TOC end -->

<!-- TOC --><a name="installation"></a>

## Installation

To install Taskchamp, download the latest [release from the App Store](https://apps.apple.com/us/app/taskchamp-tasks-for-devs/id6633442700).

Taskchamp can work as a standalone iOS app, but it's recommended to use it with Taskwarrior. To install Taskwarrior, follow the instructions [here](https://taskwarrior.org/download/).

> Taskchamp is only compatible with Taskwarrior 3.0.0 or later.

<!-- TOC --><a name="setup-with-taskwarrior"></a>

## Setup with Taskwarrior

There are currently four ways to setup Taskchamp to work with Taskwarrior: using a Taskchampion Sync Server, using S3, using GCP, or using iCloud Drive.

> [!NOTE]
> You only need to setup one of these methods, not all of them.

The documentation for how sync works in Taskwarrior can be found [here](https://taskwarrior.org/docs/sync/).

<!-- TOC --><a name="setup-with-taskchampion-sync-server"></a>

### Setup with Taskchampion Sync Server

> Remote Sync works by connecting to a remote taskchampion-sync-server that will handle the synchronization of your tasks across devices.

1. Setup a Taskchampion Sync Server by following the instructions [here](https://gothenburgbitfactory.org/taskchampion-sync-server/introduction.html).

2. Connect to the server from your computer by following the instructions [here](https://man.archlinux.org/man/extra/task/task-sync.5.en#Sync_Server).

3. Open the Taskchamp app on your phone and select `Taskchampion Sync Server` as your sync service.

4. Enter the URL of your sync server, your client id and encryption secret.

5. You will be able to trigger the sync from your computer by executing: `task sync`.

- Read more about Taskwarrior sync [here](https://taskwarrior.org/docs/commands/synchronize/).

6. Run this command whenever you want to sync your tasks. You can also create a cron job to run run it every few minutes.

7. Your tasks should now be synced between your computer and your phone. You can add tasks from the command line using Taskwarrior, `task sync`, and they will appear on Taskchamp.

<!-- TOC --><a name="setup-with-s3"></a>

### Setup with S3

> S3 sync works with Amazon S3 and compatible storage services such as MinIO.

1. Setup an S3 bucket that is compatible with taskwarrior sync by following the instructions [here](https://man.archlinux.org/man/extra/task/task-sync.5.en#Amazon_Web_Services).

2. Open the Taskchamp app on your phone and select `S3` as your sync service.

3. Enter the bucket name, access key ID, secret access key and encryption secret. For Amazon S3, also enter the region. For another S3 service, enter its endpoint URL and enable path-style URLs if the provider requires them.

4. You will be able to trigger the sync from your computer by executing: `task sync`.

- Read more about Taskwarrior sync [here](https://taskwarrior.org/docs/commands/synchronize/).

5. Run this command whenever you want to sync your tasks. You can also create a cron job to run run it every few minutes.

6. Your tasks should now be synced between your computer and your phone. You can add tasks from the command line using Taskwarrior, `task sync`, and they will appear on Taskchamp.

> [!NOTE]
> If you are having issues syncing, your replicas might be out of sync. In order to fix this you can follow the following steps:
1. Select the desired sync service in Taskchamp. 
2. Close Taskchamp.
3. Make sure to have your tasks database locally saved on your pc.
4. Delete all of the contents of the bucket.
	- Note: Don't delete the bucket itself, just the contents within it.
5. Make sure to have your sync service configured on your pc's `.taskrc`
6. Trigger a sync from your pc via `task sync`
7. Add a new task on your pc via `task add`
8. Trigger another sync from your pc via `task sync`
9. Reopen Taskchamp and refresh.
> If the problem persists try to delete Taskchamp instead of steps 1. and 2. and reinstall after step 9

<!-- TOC --><a name="setup-with-gcp"></a>

### Setup with GCP

> GCP Sync works by connecting to a GCP bucket that will handle the synchronization of your tasks across devices.

1. Setup a GCP bucket that is compatible with taskwarrior sync by following the instructions [here](https://man.archlinux.org/man/extra/task/task-sync.5.en#Google_Cloud_Platform).

2. Open the Taskchamp app on your phone and select `Google Cloud Platform` as your sync service.

3. Enter the bucket name, select your GCP credentials JSON file and encryption secret.

4. You will be able to trigger the sync from your computer by executing: `task sync`.

- Read more about Taskwarrior sync [here](https://taskwarrior.org/docs/commands/synchronize/).

5. Run this command whenever you want to sync your tasks. You can also create a cron job to run run it every few minutes.

6. Your tasks should now be synced between your computer and your phone. You can add tasks from the command line using Taskwarrior, `task sync`, and they will appear on Taskchamp.

> [!NOTE]
> If you are having issues syncing, your replicas might be out of sync. In order to fix this you can follow the following steps:
1. Select the desired sync service in Taskchamp. 
2. Close Taskchamp.
3. Make sure to have your tasks database locally saved on your pc.
4. Delete all of the contents of the bucket.
	- Note: Don't delete the bucket itself, just the contents within it.
5. Make sure to have your sync service configured on your pc's `.taskrc`
6. Trigger a sync from your pc via `task sync`
7. Add a new task on your pc via `task add`
8. Trigger another sync from your pc via `task sync`
9. Reopen Taskchamp and refresh.
> If the problem persists try to delete Taskchamp instead of steps 1. and 2. and reinstall after step 9

<!-- TOC --><a name="setup-with-icloud-drive"></a>

### Setup with iCloud Drive

> Taskchamp can also use iCloud Drive to sync tasks between your computer and your phone. This is described on the Taskwarrior docs [here](https://man.archlinux.org/man/extra/task/task-sync.5.en#ALTERNATIVE:_FILE_SHARING_SERVICES).

**This sync method is not as reliable as using a sync server and is not officially supported by taskwarrior, there is a chance that it might lead to DB corruption** , it is an okay alternative if you don't want to set up server (any of the previous methods) and make sure to backup your data in case of corruption.

> [!IMPORTANT]
> The following instructions are specific for macOS.

> [!NOTE]
> **For Linux Users**
> : If you are using Linux, feel free to follow along but you might need to make some modifications.
> Linux users must use the new [iCloud Drive support in rclone](https://github.com/rclone/rclone/pull/7717)

To setup iCloud Drive Sync, follow these steps:

1. Make sure to have an iCloud account signed in on your phone and computer. Also make sure to have iCloud Drive enabled.

> Ensure that you disable "Optimize Mac Storage" in iCloud Drive's settings

2. Open the Taskchamp app on your phone and select `iCloud Sync` as your sync service. This will create a folder in iCloud Drive called `taskchamp`, this is where your tasks database file will live.

> Sometimes it may take some time for the folder to appear on the finder and files app, but you can access it via terminal.

3. After the folder is created, navigate to it from your computer, and copy your `taskchampion.sqlite3` file into `~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp/`. Replace the existing file if there is one. Once the initial database load is complete, delete the taskchampion.sqlite3 file from this folder. After removing the file, the iOS app will  perform a correct sync.

> [!NOTE]
> You do not need to move the file, just a copy will do. This is just to make sure that the files have a shared starting point.

- If you want to use a new taskwarrior database, you can skip this step.

4. Open the taskwarrior configuration file, usually located at `~/.taskrc`, and add the following line:

```bash
sync.local.server_dir=~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp
```

- This will tell Taskwarrior to use the `taskchamp` folder in iCloud Drive as a sync directory.
- This path might be a bit different depending on your system (Linux), but you can find the correct path by navigating to the `taskchamp` folder in iCloud Drive and copying the path from the finder, or accessing the directory from your terminal. In MacOS this is `Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp`.

5. You will be able to trigger the sync from your computer by executing: `task sync`.

- Read more about Taskwarrior sync [here](https://taskwarrior.org/docs/commands/synchronize/).

6. Run this command whenever you want to sync your tasks. You can also create a cron job to run run it every few minutes.

7. Your tasks should now be synced between your computer and your phone. You can add tasks from the command line using Taskwarrior, `task sync`, and they will appear on Taskchamp.

<!-- TOC --><a name="filters"></a>

## Filters

Saved filters use a subset of Taskwarrior's filter syntax. Terms are ANDed by default; use `or` and parentheses to group.

| Term | Example |
|---|---|
| Project (exact match) | `project:work` |
| Priority | `prio:H`, `priority:M`, `prio:None` |
| Status | `status:pending`, `status:completed`, `status:deleted`, `status:recurring` |
| Tags | `+home`, `-someday` |
| Recurring tasks | `recur` |
| Date comparisons | `end.after:now-1wk`, `due.before:tomorrow`, `entry.after:2026-09-01` |

Date comparisons work on `end`, `entry`, `due`, `scheduled`, `until` and `modified`, with the `after`/`before` modifiers (`above`/`below` are aliases). A task without that date never matches. Date values can be:

- Named: `now`, `today`/`sod`, `yesterday`, `tomorrow`, `eod`, `sow`, `som`, `soy`
- Absolute: `2026-09-01` or `2026-09-01T14:30`
- Relative: a named or absolute date plus an offset, e.g. `now-1wk`, `today-3d`, `som+1mo`. A bare offset such as `-2d` is relative to `now`. Units follow Taskwarrior: `s`, `min`/`m`, `h`, `d`, `wk`/`w`, `mo`, `q`, `y`.

Relative dates are recalculated every time the filter runs, so `status:completed end.after:now-1wk` always shows the last seven days. A leading `task` (from a pasted command line) is ignored. Taskchamp rejects filters containing terms it doesn't understand (for example `due:today` without a modifier) rather than silently ignoring them.

<!-- TOC --><a name="vimango-task-notes"></a>

## vimango task notes

A task's long notes live in [vimango](https://github.com/slzatz/vimango), through the VimNotes iOS app (`~/vimango_ios`). Taskchamp never reads or writes a vimango database.

1. Open a task and tap **Create vimango note** at the bottom of the screen.
2. VimNotes opens and creates the note in context "none" and folder "none", then opens it in the editor. Its frontmatter holds the task's uuid (`taskwarrior: <uuid>`), followed by an "Open task in Taskchamp" link (`taskchampdev://task/<uuid>`).
3. Taskchamp adds a `vimango: <title>` annotation to the task, and the button becomes **Open vimango note**.

VimNotes finds the note by the uuid in its frontmatter, so renaming the note doesn't break the link. The note reaches the vimango server on VimNotes' next sync.
