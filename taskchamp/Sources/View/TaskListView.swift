import SwiftData
import SwiftUI
import taskchampShared
import UIKit

// swiftlint:disable:next type_body_length
public struct TaskListView: View {
    @Environment(PathStore.self) var pathStore: PathStore
    @Environment(\.scenePhase) var scenePhase
    @Environment(GlobalState.self) var globalState: GlobalState

    @Binding var isShowingICloudAlert: Bool
    @Binding var selectedFilter: TCFilter
    @Binding var selectedSyncType: TaskchampionService.SyncType?
    @Binding var createTaskRequest: NewTaskRequest?

    @Query(sort: \TCFilter.order) var allFilters: [TCFilter]

    @State var rebuildingCache = true
    @State var tasks: [TCTask] = []
    @State var selection = Set<String>()
    @State var editMode: EditMode = .inactive
    @State var searchText = ""
    @State var isShowingFilterView = false
    @State var isShowingSyncSettings = false
    @State var isShowingAppSettings = false
    @State var isShowingNoteAlert = false
    @AppStorage(TCUserDefaults.taskCellTitleSize.rawValue) var titleSize = TaskTitleSize.small
    @State var sortType: TasksHelper.TCSortType = .init(
        rawValue: UserDefaultsManager.standard
            .getValue(forKey: .sortType) ?? TasksHelper.TCSortType.defaultSort.rawValue
    ) ?? .defaultSort

    public init(
        isShowingICloudAlert: Binding<Bool>,
        selectedFilter: Binding<TCFilter>,
        selectedSyncType: Binding<TaskchampionService.SyncType?>,
        createTaskRequest: Binding<NewTaskRequest?>
    ) {
        _isShowingICloudAlert = isShowingICloudAlert
        _selectedFilter = selectedFilter
        _selectedSyncType = selectedSyncType
        _createTaskRequest = createTaskRequest
    }

    private func sortButton(sortType: TasksHelper.TCSortType) -> some View {
        let label: String
        switch sortType {
        case .defaultSort: label = "Default"
        case .date: label = "Date"
        case .priority: label = "Priority"
        case .status: label = "Status"
        }
        if self.sortType != sortType {
            return AnyView(
                Button(label) {
                    self.sortType = sortType
                    UserDefaultsManager.standard.set(value: sortType.rawValue, forKey: .sortType)
                    updateTasks()
                }
            )
        }
        return AnyView(
            Button {
                self.sortType = sortType
                UserDefaultsManager.standard.set(value: sortType.rawValue, forKey: .sortType)
                updateTasks()
            } label: {
                Label(label, systemImage: SFSymbols.checkmark.rawValue)
            }
        )
    }

    @ViewBuilder private var headerView: some View {
        if isEditModeActive {
            Text(headerTitle)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
        } else {
            filterSwitcherMenu
        }
    }

    public var body: some View {
        List(selection: $selection) {
            // Once per list, not per row: it parses the filter.
            let pins = selectedFilter.pins
            ForEach(searchedTasks, id: \.uuid) { task in
                NavigationLink(value: task) {
                    TaskCellView(task: task, openNote: isEditModeActive ? nil : { openNote(task) }, pins: pins)
                }
                // The chevron's width goes to the description instead.
                .navigationLinkIndicatorVisibility(.hidden)
                .if(task.status != .deleted) {
                    $0.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            updateTasks([task.uuid], withStatus: task.isCompleted ? .pending : .completed)
                        } label: {
                            Label(
                                task.isCompleted ? "Undone" : "Done",
                                systemImage: task.isCompleted ? SFSymbols.backArrow.rawValue : SFSymbols.checkmark
                                    .rawValue
                            )
                        }
                        .tint(task.isCompleted ? .yellow : .green)
                        if task.status == .pending {
                            Button {
                                toggleStartStop(task)
                            } label: {
                                Label(
                                    task.isActive ? "Stop" : "Start",
                                    systemImage: task.isActive ? SFSymbols.stopFill.rawValue : SFSymbols.playFill
                                        .rawValue
                                )
                            }
                            .tint(task.isActive ? .orange : .blue)
                        }
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button(role: task.isDeleted ? .cancel : .destructive) {
                        updateTasks([task.uuid], withStatus: task.isDeleted ? .pending : .deleted)
                    } label: {
                        Label(
                            task.isDeleted ? "Restore" : "Delete",
                            systemImage: task.isDeleted ? SFSymbols.backArrow.rawValue : SFSymbols.trash.rawValue
                        )
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            }
        }
        .animation(.default, value: sortType)
        .animation(.default, value: searchText)
        .overlay(
            Group {
                if tasks.isEmpty && !rebuildingCache {
                    ContentUnavailableView {
                        Label(
                            selectedFilter.fullDescription == TCFilter.defaultFilter
                                .fullDescription ? "No new tasks" : "No tasks found",
                            systemImage: "bolt.heart"
                        )
                    } description: {
                        Text(
                            selectedFilter.fullDescription == TCFilter.defaultFilter
                                .fullDescription ? "Use this time to relax or add new tasks!" :
                                "Try changing the filters or search terms."
                        )
                    } actions: {
                        Button("New task") {
                            createTaskRequest = NewTaskRequest()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        )
        .refreshable {
            do {
                globalState.isSyncingTasks = true
                try await Task.sleep(nanoseconds: UInt64(1.5 * Double(NSEC_PER_SEC)))
                await updateTasksWithSync()
            } catch {}
        }
        .if(!tasks.isEmpty) {
            $0.searchable(text: $searchText)
        }
        .listStyle(.inset)
        // Otherwise iOS 26 pads every row up to about 52pt, and one-line rows don't get shorter.
        .environment(\.defaultMinListRowHeight, 1)
        // Same dark gray as vimango's list rows in dark mode (white in light mode).
        .scrollContentBackground(.hidden)
        .background(Color(.secondarySystemGroupedBackground))
        .onAppear {
            setupNotifications()
        }
        .toolbar {
            if #available(iOS 26.0, *) {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.fixed, placement: .bottomBar)
                if !isEditModeActive {
                    ToolbarItem(placement: .bottomBar) {
                        favoriteFiltersMenu
                    }
                    ToolbarSpacer(.fixed, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            createTaskRequest = NewTaskRequest()
                        } label: {
                            Label(
                                "New Task",
                                systemImage: SFSymbols.plus.rawValue
                            )
                        }
                        .foregroundStyle(.tint)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                if isEditModeActive {
                    Button("Complete") {
                        updateTasks(selection, withStatus: .completed)
                        selection.removeAll()
                    }
                    .disabled(selection.isEmpty)
                    Spacer()
                    Menu {
                        Button(role: .destructive) {
                            updateTasks(selection, withStatus: .deleted)
                            selection.removeAll()
                        } label: {
                            Label(
                                "Delete selected tasks",
                                systemImage: SFSymbols.trash.rawValue
                            )
                        }
                        .disabled(selection.isEmpty)
                    } label: {
                        Label("Delete", systemImage: SFSymbols.trash.rawValue)
                    }
                    .disabled(selection.isEmpty)
                } else {
                    if #unavailable(iOS 26.0) {
                        HStack {
                            Button {
                                createTaskRequest = NewTaskRequest()
                            } label: {
                                Label(
                                    "New Task",
                                    systemImage: SFSymbols.plusCircleFill.rawValue
                                )
                                .labelStyle(.titleAndIcon)
                                .imageScale(.large)
                                .bold()
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundStyle(.tint)
                            Spacer()
                            favoriteFiltersMenu
                                .imageScale(.large)
                                .bold()
                        }
                        .animation(.default, value: editMode)
                    }
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if hasSyncServer {
                    SyncButton(isSyncing: globalState.isSyncingTasks || SyncStatus.shared.isSyncing) {
                        Task { await updateTasksWithSync() }
                    }
                }
                Menu {
                    Link(
                        "Documentation",
                        destination: URL(string: "https://github.com/marriagav/taskchamp")!
                    )
                    Divider()
                    Button("App Settings") {
                        isShowingAppSettings.toggle()
                    }
                    Button("Sync Settings") {
                        isShowingSyncSettings.toggle()
                    }
                    Menu("Sort by") {
                        sortButton(sortType: .defaultSort)
                        sortButton(sortType: .date)
                        sortButton(sortType: .priority)
                        sortButton(sortType: .status)
                    }
                    Picker("Title Size", selection: $titleSize) {
                        ForEach(TaskTitleSize.allCases) { size in
                            Text(size.label).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Filters") {
                        isShowingFilterView.toggle()
                    }
                    Button("Clear filters") {
                        withAnimation {
                            selectedFilter = .defaultFilter
                            do {
                                let res = try JSONEncoder().encode(selectedFilter)
                                UserDefaultsManager.standard.set(value: res, forKey: .selectedFilter)
                            } catch { print(error) }
                        }
                    }
                    .disabled(selectedFilter.fullDescription == TCFilter.defaultFilter.fullDescription)
                } label: {
                    Label(
                        "Options",
                        systemImage: SFSymbols.ellipsisCircle.rawValue
                    )
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .bold()
                }
            }
            ToolbarItemGroup(placement: .topBarLeading) {
                if !searchedTasks.isEmpty {
                    EditButton()
                }
            }
            ToolbarItem(placement: .principal) {
                headerView
            }
        }
        .onAppear {
            updateTasks()
        }
        .onChange(of: isEditModeActive) {
            selection.removeAll()
        }
        .onChange(of: selectedFilter) {
            updateTasks()
        }
        .onChange(of: selectedSyncType) {
            updateTasks()
        }
        .onChange(of: globalState.replicaReady) { _, isReady in
            if isReady {
                updateTasks()
            }
        }
        .onChange(of: globalState.isSyncingTasks) { _, isSyncing in
            if !isSyncing {
                updateTasks()
            }
        }
        // `item:`, not `isPresented:`, so the sheet is built from the request it
        // was opened with. With `isPresented:` a deep link's request, set in the
        // same update that opened the sheet, arrived empty.
        .sheet(item: $createTaskRequest, onDismiss: {
            updateTasks()
        }, content: { request in
            CreateTaskView(
                request: request,
                // A note's task takes only the note's own context, never the filter's.
                defaultProject: request.project
                    ?? (request.noteTaskUUID == nil ? selectedFilter.requiredProject : nil) ?? ""
            )
        })
        .sheet(isPresented: $isShowingFilterView) {
            AddFilterView(selectedFilter: $selectedFilter)
        }
        .sheet(isPresented: $isShowingSyncSettings) {
            SyncServiceView(
                isShowingSyncServiceModal: $isShowingSyncSettings,
                selectedSyncType: $selectedSyncType
            )
        }
        .sheet(isPresented: $isShowingAppSettings) {
            AppSettingsView()
        }
        .alert("Can't open VimNotes", isPresented: $isShowingNoteAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("VimNotes needs to be installed to keep task notes.")
        }
        .navigationDestination(for: TCTask.self) { task in
            EditTaskView(task: task)
                .onDisappear {
                    updateTasks()
                }
        }
        // Hidden behind the principal header, but still supplies the back-button label.
        .navigationTitle(headerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .onChange(of: scenePhase) { _, newScenePhase in
            if newScenePhase == .active {
                setupNotifications()
            }
        }
    }
}
