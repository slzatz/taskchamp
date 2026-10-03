import RustXcframework
public func new_replica_in_memory() -> Replica {
    Replica(ptr: __swift_bridge__$new_replica_in_memory())
}
public func new_replica_on_disk<GenericIntoRustString: IntoRustString>(_ taskdb_dir: GenericIntoRustString, _ create_if_missing: Bool, _ read_write: Bool) -> Replica {
    Replica(ptr: __swift_bridge__$new_replica_on_disk({ let rustString = taskdb_dir.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), create_if_missing, read_write))
}
public func new_operations() -> RustVec<Operation> {
    RustVec(ptr: __swift_bridge__$new_operations())
}
public func create_tag<GenericIntoRustString: IntoRustString>(_ value: GenericIntoRustString) -> Optional<Tag> {
    { let val = __swift_bridge__$create_tag({ let rustString = value.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); if val != nil { return Tag(ptr: val!) } else { return nil } }()
}
public func create_annotation<GenericIntoRustString: IntoRustString>(_ description: GenericIntoRustString, _ entry: GenericIntoRustString) -> Optional<Annotation> {
    { let val = __swift_bridge__$create_annotation({ let rustString = description.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { let rustString = entry.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); if val != nil { return Annotation(ptr: val!) } else { return nil } }()
}
public func uuid_v4() -> Uuid {
    Uuid(ptr: __swift_bridge__$uuid_v4())
}

public class Replica: ReplicaRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Replica$_free(ptr)
        }
    }
}
public class ReplicaRefMut: ReplicaRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
extension ReplicaRefMut {
    public func all_task_data() -> Optional<RustVec<TaskData>> {
        { let val = __swift_bridge__$Replica$all_task_data(ptr); if val != nil { return RustVec(ptr: val!) } else { return nil } }()
    }

    public func all_tasks() -> Optional<RustVec<Task>> {
        { let val = __swift_bridge__$Replica$all_tasks(ptr); if val != nil { return RustVec(ptr: val!) } else { return nil } }()
    }

    public func get_task<GenericIntoRustString: IntoRustString>(_ uuid: GenericIntoRustString) -> Optional<Task> {
        { let val = __swift_bridge__$Replica$get_task(ptr, { let rustString = uuid.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); if val != nil { return Task(ptr: val!) } else { return nil } }()
    }

    public func pending_tasks() -> Optional<RustVec<Task>> {
        { let val = __swift_bridge__$Replica$pending_tasks(ptr); if val != nil { return RustVec(ptr: val!) } else { return nil } }()
    }

    public func commit_operations(_ ops: RustVec<Operation>) {
        __swift_bridge__$Replica$commit_operations(ptr, { let val = ops; val.isOwned = false; return val.ptr }())
    }

    public func sync_local_server<GenericIntoRustString: IntoRustString>(_ server_dir: GenericIntoRustString) -> Bool {
        __swift_bridge__$Replica$sync_local_server(ptr, { let rustString = server_dir.intoRustString(); rustString.isOwned = false; return rustString.ptr }())
    }

    public func sync_no_server() -> Bool {
        __swift_bridge__$Replica$sync_no_server(ptr)
    }

    public func sync_remote_server<GenericIntoRustString: IntoRustString>(_ url: GenericIntoRustString, _ client_id: GenericIntoRustString, _ encryption_secret: GenericIntoRustString) -> Bool {
        __swift_bridge__$Replica$sync_remote_server(ptr, { let rustString = url.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { let rustString = client_id.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { let rustString = encryption_secret.intoRustString(); rustString.isOwned = false; return rustString.ptr }())
    }

    public func sync_gcp<GenericIntoRustString: IntoRustString>(_ bucket: GenericIntoRustString, _ credential_path: Optional<GenericIntoRustString>, _ encryption_secret: GenericIntoRustString) -> Bool {
        __swift_bridge__$Replica$sync_gcp(ptr, { let rustString = bucket.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { if let rustString = optionalStringIntoRustString(credential_path) { rustString.isOwned = false; return rustString.ptr } else { return nil } }(), { let rustString = encryption_secret.intoRustString(); rustString.isOwned = false; return rustString.ptr }())
    }

    public func sync_aws<GenericIntoRustString: IntoRustString>(_ region: Optional<GenericIntoRustString>, _ bucket: GenericIntoRustString, _ endpoint_url: Optional<GenericIntoRustString>, _ force_path_style: Bool, _ access_key_id: GenericIntoRustString, _ secret_access_key: GenericIntoRustString, _ encryption_secret: GenericIntoRustString) -> Bool {
        __swift_bridge__$Replica$sync_aws(ptr, { if let rustString = optionalStringIntoRustString(region) { rustString.isOwned = false; return rustString.ptr } else { return nil } }(), { let rustString = bucket.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { if let rustString = optionalStringIntoRustString(endpoint_url) { rustString.isOwned = false; return rustString.ptr } else { return nil } }(), force_path_style, { let rustString = access_key_id.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { let rustString = secret_access_key.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { let rustString = encryption_secret.intoRustString(); rustString.isOwned = false; return rustString.ptr }())
    }

    public func create_task<GenericIntoRustString: IntoRustString>(_ uuid: GenericIntoRustString, _ description: GenericIntoRustString, _ due: Optional<GenericIntoRustString>, _ priority: Optional<GenericIntoRustString>, _ project: Optional<GenericIntoRustString>, _ tags: Optional<RustVec<Tag>>) -> Optional<Task> {
        { let val = __swift_bridge__$Replica$create_task(ptr, { let rustString = uuid.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { let rustString = description.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { if let rustString = optionalStringIntoRustString(due) { rustString.isOwned = false; return rustString.ptr } else { return nil } }(), { if let rustString = optionalStringIntoRustString(priority) { rustString.isOwned = false; return rustString.ptr } else { return nil } }(), { if let rustString = optionalStringIntoRustString(project) { rustString.isOwned = false; return rustString.ptr } else { return nil } }(), { if let val = tags { val.isOwned = false; return val.ptr } else { return nil } }()); if val != nil { return Task(ptr: val!) } else { return nil } }()
    }

    public func update_task<GenericIntoRustString: IntoRustString>(_ uuid: GenericIntoRustString, _ description: GenericIntoRustString, _ due: Optional<GenericIntoRustString>, _ priority: Optional<GenericIntoRustString>, _ project: Optional<GenericIntoRustString>, _ status: GenericIntoRustString, _ annotations: Optional<RustVec<Annotation>>, _ tags: Optional<RustVec<Tag>>) -> Optional<Task> {
        { let val = __swift_bridge__$Replica$update_task(ptr, { let rustString = uuid.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { let rustString = description.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { if let rustString = optionalStringIntoRustString(due) { rustString.isOwned = false; return rustString.ptr } else { return nil } }(), { if let rustString = optionalStringIntoRustString(priority) { rustString.isOwned = false; return rustString.ptr } else { return nil } }(), { if let rustString = optionalStringIntoRustString(project) { rustString.isOwned = false; return rustString.ptr } else { return nil } }(), { let rustString = status.intoRustString(); rustString.isOwned = false; return rustString.ptr }(), { if let val = annotations { val.isOwned = false; return val.ptr } else { return nil } }(), { if let val = tags { val.isOwned = false; return val.ptr } else { return nil } }()); if val != nil { return Task(ptr: val!) } else { return nil } }()
    }

    public func start_task<GenericIntoRustString: IntoRustString>(_ uuid: GenericIntoRustString) -> Optional<Task> {
        { let val = __swift_bridge__$Replica$start_task(ptr, { let rustString = uuid.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); if val != nil { return Task(ptr: val!) } else { return nil } }()
    }

    public func stop_task<GenericIntoRustString: IntoRustString>(_ uuid: GenericIntoRustString) -> Optional<Task> {
        { let val = __swift_bridge__$Replica$stop_task(ptr, { let rustString = uuid.intoRustString(); rustString.isOwned = false; return rustString.ptr }()); if val != nil { return Task(ptr: val!) } else { return nil } }()
    }
}
public class ReplicaRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension Replica: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Replica$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Replica$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Replica) {
        __swift_bridge__$Vec_Replica$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Replica$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Replica(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<ReplicaRef> {
        let pointer = __swift_bridge__$Vec_Replica$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return ReplicaRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<ReplicaRefMut> {
        let pointer = __swift_bridge__$Vec_Replica$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return ReplicaRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<ReplicaRef> {
        UnsafePointer<ReplicaRef>(OpaquePointer(__swift_bridge__$Vec_Replica$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Replica$len(vecPtr)
    }
}


public class Operation: OperationRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Operation$_free(ptr)
        }
    }
}
public class OperationRefMut: OperationRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class OperationRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension Operation: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Operation$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Operation$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Operation) {
        __swift_bridge__$Vec_Operation$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Operation$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Operation(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<OperationRef> {
        let pointer = __swift_bridge__$Vec_Operation$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return OperationRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<OperationRefMut> {
        let pointer = __swift_bridge__$Vec_Operation$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return OperationRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<OperationRef> {
        UnsafePointer<OperationRef>(OpaquePointer(__swift_bridge__$Vec_Operation$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Operation$len(vecPtr)
    }
}


public class TaskData: TaskDataRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$TaskData$_free(ptr)
        }
    }
}
public class TaskDataRefMut: TaskDataRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class TaskDataRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension TaskDataRef {
    public func get_uuid() -> Uuid {
        Uuid(ptr: __swift_bridge__$TaskData$get_uuid(ptr))
    }
}
extension TaskData: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_TaskData$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_TaskData$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: TaskData) {
        __swift_bridge__$Vec_TaskData$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_TaskData$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (TaskData(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<TaskDataRef> {
        let pointer = __swift_bridge__$Vec_TaskData$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return TaskDataRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<TaskDataRefMut> {
        let pointer = __swift_bridge__$Vec_TaskData$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return TaskDataRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<TaskDataRef> {
        UnsafePointer<TaskDataRef>(OpaquePointer(__swift_bridge__$Vec_TaskData$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_TaskData$len(vecPtr)
    }
}


public class Tag: TagRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Tag$_free(ptr)
        }
    }
}
public class TagRefMut: TagRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class TagRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension TagRef {
    public func get_value() -> RustString {
        RustString(ptr: __swift_bridge__$Tag$get_value(ptr))
    }

    public func is_synthetic() -> Bool {
        __swift_bridge__$Tag$is_synthetic(ptr)
    }
}
extension Tag: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Tag$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Tag$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Tag) {
        __swift_bridge__$Vec_Tag$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Tag$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Tag(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<TagRef> {
        let pointer = __swift_bridge__$Vec_Tag$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return TagRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<TagRefMut> {
        let pointer = __swift_bridge__$Vec_Tag$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return TagRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<TagRef> {
        UnsafePointer<TagRef>(OpaquePointer(__swift_bridge__$Vec_Tag$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Tag$len(vecPtr)
    }
}


public class Task: TaskRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Task$_free(ptr)
        }
    }
}
public class TaskRefMut: TaskRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class TaskRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension TaskRef {
    public func get_uuid() -> Uuid {
        Uuid(ptr: __swift_bridge__$Task$get_uuid(ptr))
    }

    public func get_description() -> RustString {
        RustString(ptr: __swift_bridge__$Task$get_description(ptr))
    }

    public func get_status() -> Status {
        Status(ptr: __swift_bridge__$Task$get_status(ptr))
    }

    public func get_due() -> Optional<RustString> {
        { let val = __swift_bridge__$Task$get_due(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }

    public func get_priority() -> RustString {
        RustString(ptr: __swift_bridge__$Task$get_priority(ptr))
    }

    public func get_annotations() -> RustVec<Annotation> {
        RustVec(ptr: __swift_bridge__$Task$get_annotations(ptr))
    }

    public func get_project() -> Optional<RustString> {
        { let val = __swift_bridge__$Task$get_project(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }

    public func get_tags() -> RustVec<Tag> {
        RustVec(ptr: __swift_bridge__$Task$get_tags(ptr))
    }

    public func get_recur() -> Optional<RustString> {
        { let val = __swift_bridge__$Task$get_recur(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }

    public func get_start() -> Optional<RustString> {
        { let val = __swift_bridge__$Task$get_start(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }

    public func get_scheduled() -> Optional<RustString> {
        { let val = __swift_bridge__$Task$get_scheduled(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }

    public func get_until() -> Optional<RustString> {
        { let val = __swift_bridge__$Task$get_until(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }

    public func get_modified() -> Optional<RustString> {
        { let val = __swift_bridge__$Task$get_modified(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }

    public func get_end() -> Optional<RustString> {
        { let val = __swift_bridge__$Task$get_end(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }

    public func get_entry() -> Optional<RustString> {
        { let val = __swift_bridge__$Task$get_entry(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }
}
extension Task: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Task$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Task$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Task) {
        __swift_bridge__$Vec_Task$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Task$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Task(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<TaskRef> {
        let pointer = __swift_bridge__$Vec_Task$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return TaskRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<TaskRefMut> {
        let pointer = __swift_bridge__$Vec_Task$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return TaskRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<TaskRef> {
        UnsafePointer<TaskRef>(OpaquePointer(__swift_bridge__$Vec_Task$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Task$len(vecPtr)
    }
}


public class Annotation: AnnotationRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Annotation$_free(ptr)
        }
    }
}
public class AnnotationRefMut: AnnotationRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class AnnotationRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension AnnotationRef {
    public func get_description() -> RustString {
        RustString(ptr: __swift_bridge__$Annotation$get_description(ptr))
    }
}
extension Annotation: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Annotation$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Annotation$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Annotation) {
        __swift_bridge__$Vec_Annotation$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Annotation$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Annotation(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<AnnotationRef> {
        let pointer = __swift_bridge__$Vec_Annotation$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return AnnotationRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<AnnotationRefMut> {
        let pointer = __swift_bridge__$Vec_Annotation$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return AnnotationRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<AnnotationRef> {
        UnsafePointer<AnnotationRef>(OpaquePointer(__swift_bridge__$Vec_Annotation$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Annotation$len(vecPtr)
    }
}


public class Status: StatusRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Status$_free(ptr)
        }
    }
}
public class StatusRefMut: StatusRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class StatusRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension StatusRef {
    public func get_value() -> RustString {
        RustString(ptr: __swift_bridge__$Status$get_value(ptr))
    }
}
extension Status: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Status$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Status$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Status) {
        __swift_bridge__$Vec_Status$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Status$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Status(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<StatusRef> {
        let pointer = __swift_bridge__$Vec_Status$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return StatusRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<StatusRefMut> {
        let pointer = __swift_bridge__$Vec_Status$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return StatusRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<StatusRef> {
        UnsafePointer<StatusRef>(OpaquePointer(__swift_bridge__$Vec_Status$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Status$len(vecPtr)
    }
}


public class Uuid: UuidRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Uuid$_free(ptr)
        }
    }
}
public class UuidRefMut: UuidRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class UuidRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension UuidRef {
    public func to_string() -> RustString {
        RustString(ptr: __swift_bridge__$Uuid$to_string(ptr))
    }
}
extension Uuid: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Uuid$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Uuid$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Uuid) {
        __swift_bridge__$Vec_Uuid$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Uuid$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Uuid(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<UuidRef> {
        let pointer = __swift_bridge__$Vec_Uuid$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return UuidRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<UuidRefMut> {
        let pointer = __swift_bridge__$Vec_Uuid$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return UuidRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<UuidRef> {
        UnsafePointer<UuidRef>(OpaquePointer(__swift_bridge__$Vec_Uuid$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Uuid$len(vecPtr)
    }
}
