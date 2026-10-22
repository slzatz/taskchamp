import SwiftUI
import Taskchampion

// MARK: - SyncServiceProtocol

public protocol SyncServiceProtocol: Sendable {
    static var syncServiceType: TaskchampionService.SyncType { get }
    static var settingName: String { get }
    static var errorTitle: String { get }
    static var errorMessage: String { get }
    /// Syncs `replica` with the backend, blocking until done. Called by `TaskchampionService`
    /// on its serial sync queue with the dedicated sync replica; never call it on the main thread.
    static func sync(replica: Replica) throws -> Bool
    /// Asks the backend, without syncing, whether it has changes the database in `path` hasn't
    /// pulled. Nil when it can't tell. Blocks on the network, so never call it on the main thread.
    static func probe(path: String) -> Bool?
    static func isAvailable() -> Bool
}

public extension SyncServiceProtocol {
    /// No sync, and iCloud Sync (hidden in this fork), have no server to ask.
    static func probe(path _: String) -> Bool? {
        return nil
    }

    /// The bridge's probe result: 1 the server has changes, 0 it hasn't, -1 it couldn't tell.
    static func probeAnswer(_ code: Int32) -> Bool? {
        switch code {
        case 1: return true
        case 0: return false
        default: return nil
        }
    }
}

// MARK: - NoSyncService

public final class NoSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .none
    public static let settingName = "No Sync Service"
    public static let errorTitle = "Unexpected Error"
    public static let errorMessage = "Please try again later"

    private init() {}

    public static func isAvailable() -> Bool {
        return true
    }

    public static func sync(replica: Replica) throws -> Bool {
        return replica.sync_no_server()
    }
}

// MARK: - ICloudSyncService

public final class ICloudSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .local
    public static let settingName = "iCloud Sync"
    public static let errorTitle = "iCloud Required"
    public static let errorMessage =
        "In order to use Taskchamp with iCloud Sync, you require to have an iCloud account and iCloud Drive enabled"

    private init() {}

    public static func isAvailable() -> Bool {
        return FileService.shared.isICloudAvailable()
    }

    public static func sync(replica: Replica) throws -> Bool {
        do {
            let icloudPath = try FileService.shared.getDestinationPathForICloudServer()
            return replica.sync_local_server(icloudPath)
        } catch {
            throw TCError.genericError("Failed to sync with iCloud: \(error.localizedDescription)")
        }
    }
}

public final class RemoteSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .remote
    public static let settingName = "Taskchampion Sync Server"
    public static let errorTitle = "There was an error"
    public static let errorMessage =
        "Make sure that you have the `taskchampion-sync-server` running"

    private init() {}

    public static func getRemoteServerUrl() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .remoteServerUrl)
    }

    public static func getRemoteClientId() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .remoteServerClientId)
    }

    public static func getRemoteEncryptionSecret() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .remoteServerEncryptionSecret)
    }

    public static func isAvailable() -> Bool {
        return getRemoteServerUrl() != nil &&
            getRemoteClientId() != nil &&
            getRemoteEncryptionSecret() != nil
    }

    public static func sync(replica: Replica) throws -> Bool {
        // swiftlint:disable all
        guard let remoteServerUrl = getRemoteServerUrl(),
              let remoteClientId = getRemoteClientId(),
              let remoteEncryptionSecret = getRemoteEncryptionSecret()
        else {
            // swiftlint:enable all
            throw TCError.genericError("Remote server configuration is incomplete")
        }

        return replica.sync_remote_server(
            remoteServerUrl.intoRustString(),
            remoteClientId.intoRustString(),
            remoteEncryptionSecret.intoRustString()
        )
    }

    public static func probe(path: String) -> Bool? {
        guard let remoteServerUrl = getRemoteServerUrl(),
              let remoteClientId = getRemoteClientId(),
              let remoteEncryptionSecret = getRemoteEncryptionSecret()
        else {
            return nil
        }

        return probeAnswer(Taskchampion.probe_remote_server(
            path.intoRustString(),
            remoteServerUrl.intoRustString(),
            remoteClientId.intoRustString(),
            remoteEncryptionSecret.intoRustString()
        ))
    }
}

public final class GcpSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .gcp
    public static let settingName = "Google Cloud Platform"
    public static let errorTitle = "There was an error"
    public static let errorMessage =
        "Make sure that you have the correct GCP configuration"

    private init() {}

    public static func getGcpBucket() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .gcpServerBucket)
    }

    public static func getGcpCredentialPath() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .gcpServerCredentialPath)
    }

    public static func getGcpEncryptionSecret() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .gcpServerEncryptionSecret)
    }

    public static func isAvailable() -> Bool {
        return getGcpBucket() != nil &&
            getGcpEncryptionSecret() != nil
    }

    public static func sync(replica: Replica) throws -> Bool {
        // swiftlint:disable all
        guard let bucket = getGcpBucket(),
              let encryptionSecret = getGcpEncryptionSecret()
        else {
            // swiftlint:enable all
            throw TCError.genericError("GCP configuration is incomplete")
        }

        return replica.sync_gcp(
            bucket.intoRustString(),
            getGcpCredentialPath()?.intoRustString(),
            encryptionSecret.intoRustString()
        )
    }

    public static func probe(path: String) -> Bool? {
        guard let bucket = getGcpBucket(),
              let encryptionSecret = getGcpEncryptionSecret()
        else {
            return nil
        }

        return probeAnswer(Taskchampion.probe_gcp(
            path.intoRustString(),
            bucket.intoRustString(),
            getGcpCredentialPath()?.intoRustString(),
            encryptionSecret.intoRustString()
        ))
    }
}

public final class AwsSyncService: SyncServiceProtocol {
    public static let syncServiceType: TaskchampionService.SyncType = .aws
    public static let settingName = "S3"
    public static let errorTitle = "There was an error"
    public static let errorMessage =
        "Make sure that you have the correct S3 configuration"

    public static func getAwsBucket() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerBucket)
    }

    public static func getAwsRegion() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerRegion)
    }

    public static func getAwsEndpointUrl() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerEndpointUrl)
    }

    public static func getAwsForcePathStyle() -> Bool {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerForcePathStyle) ?? false
    }

    public static func getAwsAccessKeyId() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerAccessKeyId)
    }

    public static func getAwsSecretAccessKey() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerSecretAccessKey)
    }

    public static func getAwsEncryptionSecret() -> String? {
        return UserDefaultsManager.shared.getValue(forKey: .awsServerEncryptionSecret)
    }

    private init() {}

    public static func isAvailable() -> Bool {
        return getAwsBucket() != nil &&
            getAwsAccessKeyId() != nil &&
            getAwsSecretAccessKey() != nil &&
            getAwsEncryptionSecret() != nil
    }

    public static func sync(replica: Replica) throws -> Bool {
        // swiftlint:disable all
        guard let bucket = getAwsBucket(),
              let accessKeyId = getAwsAccessKeyId(),
              let secretAccessKey = getAwsSecretAccessKey(),
              let encryptionSecret = getAwsEncryptionSecret()
        else {
            // swiftlint:enable all
            throw TCError.genericError("S3 configuration is incomplete")
        }

        return replica.sync_aws(
            nonEmptyString(getAwsRegion())?.intoRustString(),
            bucket.intoRustString(),
            nonEmptyString(getAwsEndpointUrl())?.intoRustString(),
            getAwsForcePathStyle(),
            accessKeyId.intoRustString(),
            secretAccessKey.intoRustString(),
            encryptionSecret.intoRustString()
        )
    }

    public static func probe(path: String) -> Bool? {
        guard let bucket = getAwsBucket(),
              let accessKeyId = getAwsAccessKeyId(),
              let secretAccessKey = getAwsSecretAccessKey(),
              let encryptionSecret = getAwsEncryptionSecret()
        else {
            return nil
        }

        return probeAnswer(Taskchampion.probe_aws(
            path.intoRustString(),
            nonEmptyString(getAwsRegion())?.intoRustString(),
            bucket.intoRustString(),
            nonEmptyString(getAwsEndpointUrl())?.intoRustString(),
            getAwsForcePathStyle(),
            accessKeyId.intoRustString(),
            secretAccessKey.intoRustString(),
            encryptionSecret.intoRustString()
        ))
    }

    private static func nonEmptyString(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value
    }
}
