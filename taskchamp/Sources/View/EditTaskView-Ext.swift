import Foundation
import taskchampShared
import UIKit

extension EditTaskView {
    var didChange: Bool {
        let timeForSave: Date? = didSetTime
            ? time
            : (didSetDate ? UserDefaultsManager.standard.defaultDueTime() : nil)
        return task.project ?? "" != project ||
            task.description != description ||
            task.status != status ||
            task.priority != (priority == TCTask.Priority.none ? nil : priority) ||
            task.due != Calendar.current.mergeDateWithTime(
                date: didSetDate ? due : nil,
                time: timeForSave
            ) ||
            task.tags ?? [] != tags
    }

    func calculateNextField() {
        focusedField = nil
    }

    func calculatePreviousField() {
        focusedField = nil
    }

    func onDismissKeyboard() {
        focusedField = nil
    }

    /// Opens the task's note in VimNotes, which finds it by the task's uuid or
    /// creates it. The task is annotated only once VimNotes has taken the URL.
    func handleVimangoTap() {
        var components = URLComponents()
        components.scheme = "vimango"
        components.host = "task-note"
        components.queryItems = [
            URLQueryItem(name: "uuid", value: task.uuid),
            URLQueryItem(name: "title", value: task.description)
        ]
        if let project = task.project, !project.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "project", value: project))
        }
        guard let url = components.url else {
            return
        }
        UIApplication.shared.open(url) { opened in
            guard opened else {
                isShowingAlert = true
                alertTitle = "Can't open VimNotes"
                alertMessage = "VimNotes needs to be installed to keep task notes."
                return
            }
            guard !task.hasNote else {
                return
            }
            do {
                try TaskchampionService.shared.linkVimangoNote(uuid: task.uuid, title: task.description)
                task = try TaskchampionService.shared.getTask(uuid: task.uuid)
            } catch {
                isShowingAlert = true
                alertTitle = "There was an error"
                alertMessage = "The note was opened, but the task couldn't be marked as having one."
            }
        }
    }

    func handleStartStopTap() {
        do {
            globalState.isSyncingTasks = true
            if task.isActive {
                try TaskchampionService.shared.stopTask(task.uuid) {
                    globalState.isSyncingTasks = false
                }
                task = try TaskchampionService.shared.getTask(uuid: task.uuid)
                return
            }
            try TaskchampionService.shared.startTask(task.uuid) {
                globalState.isSyncingTasks = false
            }
            task = try TaskchampionService.shared.getTask(uuid: task.uuid)
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Failed to \(task.isActive ? "stop" : "start") task. Please try again."
        }
    }

    func handleTaskActionTap() {
        do {
            globalState.isSyncingTasks = true
            let newStatus: TCTask.Status = task.isCompleted ? .pending : task
                .isDeleted ? .pending : .completed
            try TaskchampionService.shared.updatePendingTasks(
                [task.uuid],
                withStatus: newStatus
            ) {
                globalState.isSyncingTasks = false
            }
            if (newStatus == .completed) || (newStatus == .deleted) {
                NotificationService.shared.deleteReminderForTask(task: task)
            } else {
                NotificationService.shared.createReminderForTask(task: task)
            }
            dismiss()
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Task failed to update. Please try again."
        }
    }

    func updateTask() {
        if description.isEmpty {
            isShowingAlert = true
            alertTitle = "Missing field"
            alertMessage = "Please enter a task name"
            return
        }

        let date: Date? = didSetDate ? due : nil
        let time: Date? = didSetTime
            ? time
            : (didSetDate ? UserDefaultsManager.standard.defaultDueTime() : nil)
        let finalDate = Calendar.current.mergeDateWithTime(date: date, time: time)
        let tags = tags.isEmpty ? nil : tags

        let task = TCTask(
            uuid: task.uuid,
            project: project.isEmpty ? nil : project,
            description: description,
            status: status,
            priority: priority == .none ? nil : priority,
            due: finalDate,
            tags: tags,
            recur: task.recur
        )

        do {
            globalState.isSyncingTasks = true
            try TaskchampionService.shared.updateTask(task) {
                globalState.isSyncingTasks = false
            }
            NotificationService.shared.createReminderForTask(task: task)
            dismiss()
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Task failed to update. Please try again."
        }
    }

    func deleteTask() {
        do {
            globalState.isSyncingTasks = true
            try TaskchampionService.shared.updatePendingTasks([task.uuid], withStatus: .deleted) {
                globalState.isSyncingTasks = false
            }
            NotificationService.shared.deleteReminderForTask(task: task)
            dismiss()
        } catch {
            isShowingAlert = true
            alertTitle = "There was an error"
            alertMessage = "Task failed to update. Please try again."
        }
    }
}
