import CloudKit
import CoreData
import Foundation

extension Notification.Name {
    static let recordingCloudStoreDidChange = Notification.Name("recordingCloudStoreDidChange")
}

@objc(CloudRecording)
final class CloudRecording: NSManagedObject {
    @NSManaged var recordID: String?
    @NSManaged var fileName: String?
    @NSManaged var fileExtension: String?
    @NSManaged var createdAt: Date?
    @NSManaged var duration: Double
    @NSManaged var title: String?
    @NSManaged var languageIdentifier: String?
    @NSManaged var transcript: String?
    @NSManaged var tagTimesData: Data?
    @NSManaged var recordedAt: Date?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var altitude: Double
    @NSManaged var horizontalAccuracy: Double
    @NSManaged var locationTimestamp: Date?
    @NSManaged var locationAddress: String?
    @NSManaged var fileFormat: String?
    @NSManaged var sampleRate: Double
    @NSManaged var bitDepth: Int16
    @NSManaged var channelCount: Int16
    @NSManaged var inputName: String?
    @NSManaged var inputUID: String?
    @NSManaged var inputPortType: String?
    @NSManaged var noiseReductionMode: String?
    @NSManaged var echoCancellationMode: String?
    @NSManaged var encoding: String?
    @NSManaged var modifiedAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var fileByteCount: Int64
    @NSManaged var fileModificationDate: Date?
    @NSManaged var audioData: Data?
    @NSManaged var isDeletedRecord: Bool
}

final class CloudSyncStore {
    static let shared = CloudSyncStore()
    static let containerIdentifier = "iCloud.com.lutan.RetroRecorder"

    private let container: NSPersistentCloudKitContainer
    private let context: NSManagedObjectContext
    private var isReady = false
    private var remoteChangeObserver: NSObjectProtocol?
    private var pendingDeletedRecordIDs = Set<String>()

    private init() {
        let model = Self.makeModel()
        container = NSPersistentCloudKitContainer(name: "RetroRecorderCloud", managedObjectModel: model)

        let storeDescription = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        storeDescription.url = supportDirectory.appendingPathComponent("RetroRecorderCloud.sqlite")
        storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: Self.containerIdentifier
        )
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [storeDescription]

        context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.isReady = true
            NotificationCenter.default.post(name: .recordingCloudStoreDidChange, object: self)
        }

        container.loadPersistentStores { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isReady = error == nil
                if let error {
                    print("CloudKit store unavailable: \(error.localizedDescription)")
                } else {
                    self.flushPendingDeletes()
                }
                NotificationCenter.default.post(name: .recordingCloudStoreDidChange, object: self)
            }
        }
    }

    deinit {
        if let remoteChangeObserver {
            NotificationCenter.default.removeObserver(remoteChangeObserver)
        }
    }

    func reconcile(localRecordings: [RecordingItem]) {
        guard isReady else { return }

        for recording in localRecordings {
            sync(recording: recording)
        }
    }

    func sync(recordingURL: URL) {
        guard let recording = RecordingStore.loadRecording(at: recordingURL) else { return }
        sync(recording: recording)
    }

    func sync(recording: RecordingItem) {
        guard isReady else { return }

        let recordID = cloudRecordID(for: recording)
        let managed = fetch(recordID: recordID) ?? CloudRecording(context: context)
        let isNew = managed.recordID == nil
        let localModifiedAt = recording.metadata.modifiedAt ?? recording.createdAt
        let cloudModifiedAt = managed.updatedAt ?? .distantPast
        let localFileByteCount = fileByteCount(for: recording.url)
        let needsAudioSync = managed.audioData == nil || managed.fileByteCount != localFileByteCount

        if managed.isDeletedRecord,
           localModifiedAt <= cloudModifiedAt,
           !isNew {
            return
        }

        managed.recordID = recordID
        managed.fileName = recording.url.lastPathComponent
        managed.fileExtension = recording.url.pathExtension
        managed.createdAt = recording.createdAt
        managed.duration = recording.duration
        managed.fileByteCount = localFileByteCount
        managed.fileModificationDate = fileModificationDate(for: recording.url)
        managed.isDeletedRecord = false

        if isNew || localModifiedAt > cloudModifiedAt {
            copyMetadata(from: recording, to: managed)
        }

        if needsAudioSync {
            managed.audioData = try? Data(contentsOf: recording.url)
        }

        managed.updatedAt = max(cloudModifiedAt, localModifiedAt)
        saveContext()
    }

    func restoreCloudRecordings() {
        guard isReady else { return }

        let request = NSFetchRequest<CloudRecording>(entityName: "CloudRecording")
        let records = (try? context.fetch(request)) ?? []

        for record in records {
            guard let fileName = record.fileName,
                  !fileName.isEmpty else {
                continue
            }

            let url = RecordingStore.directory.appendingPathComponent(fileName)

            if record.isDeletedRecord {
                removeLocalFiles(at: url)
                continue
            }

            let localMetadata = RecordingStore.metadata(for: url)
            let localModifiedAt = localMetadata.modifiedAt ?? (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let cloudModifiedAt = record.updatedAt ?? .distantPast
            let shouldApplyMetadata = !FileManager.default.fileExists(atPath: url.path) || cloudModifiedAt > localModifiedAt
            let localFileSize = fileByteCount(for: url)
            let shouldApplyAudio = record.audioData != nil &&
                (!FileManager.default.fileExists(atPath: url.path) || localFileSize != record.fileByteCount)

            if shouldApplyAudio, let audioData = record.audioData {
                try? FileManager.default.createDirectory(at: RecordingStore.directory, withIntermediateDirectories: true)
                try? audioData.write(to: url, options: .atomic)
            }

            if shouldApplyMetadata {
                let metadata = makeMetadata(from: record)
                try? RecordingStore.writeMetadata(metadata, for: url)

                if let transcript = record.transcript,
                   transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    try? RecordingStore.writeTranscript(transcript, for: url)
                } else {
                    removeLocalTranscript(for: url)
                }
            }
        }
    }

    func markDeleted(recording: RecordingItem) {
        let recordID = cloudRecordID(for: recording)
        guard isReady else {
            pendingDeletedRecordIDs.insert(recordID)
            return
        }

        let managed = fetch(recordID: recordID) ?? CloudRecording(context: context)
        managed.recordID = recordID
        managed.fileName = recording.url.lastPathComponent
        managed.fileExtension = recording.url.pathExtension
        managed.isDeletedRecord = true
        managed.audioData = nil
        managed.updatedAt = Date()
        saveContext()
    }

    private func flushPendingDeletes() {
        guard isReady else { return }
        let pending = pendingDeletedRecordIDs
        pendingDeletedRecordIDs.removeAll()

        for recordID in pending {
            let managed = fetch(recordID: recordID) ?? CloudRecording(context: context)
            managed.recordID = recordID
            managed.isDeletedRecord = true
            managed.audioData = nil
            managed.updatedAt = Date()
        }

        saveContext()
    }

    private func fetch(recordID: String) -> CloudRecording? {
        let request = NSFetchRequest<CloudRecording>(entityName: "CloudRecording")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "recordID == %@", recordID)
        return try? context.fetch(request).first
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CloudKit store save failed: \(error.localizedDescription)")
        }
    }

    private func copyMetadata(from recording: RecordingItem, to managed: CloudRecording) {
        let metadata = recording.metadata
        managed.title = metadata.title
        managed.languageIdentifier = metadata.languageIdentifier
        managed.transcript = recording.transcript
        managed.tagTimesData = try? JSONEncoder().encode(recording.tagTimes)
        managed.recordedAt = metadata.recordedAt
        managed.latitude = metadata.location?.latitude ?? 0
        managed.longitude = metadata.location?.longitude ?? 0
        managed.altitude = metadata.location?.altitude ?? 0
        managed.horizontalAccuracy = metadata.location?.horizontalAccuracy ?? -1
        managed.locationTimestamp = metadata.location?.timestamp
        managed.locationAddress = metadata.location?.address
        managed.fileFormat = metadata.fileFormat
        managed.sampleRate = metadata.sampleRate ?? 0
        managed.bitDepth = Int16(metadata.bitDepth ?? 0)
        managed.channelCount = Int16(metadata.channelCount ?? 0)
        managed.inputName = metadata.inputName
        managed.inputUID = metadata.inputUID
        managed.inputPortType = metadata.inputPortType
        managed.noiseReductionMode = metadata.noiseReductionMode
        managed.echoCancellationMode = metadata.echoCancellationMode
        managed.encoding = metadata.encoding
        managed.modifiedAt = metadata.modifiedAt
    }

    private func makeMetadata(from managed: CloudRecording) -> RecordingMetadata {
        let tagTimes = (try? JSONDecoder().decode([TimeInterval].self, from: managed.tagTimesData ?? Data()))
        let location: RecordingLocationMetadata?
        if managed.latitude != 0 || managed.longitude != 0 || managed.locationAddress != nil {
            location = RecordingLocationMetadata(
                latitude: managed.latitude,
                longitude: managed.longitude,
                altitude: managed.altitude == 0 ? nil : managed.altitude,
                horizontalAccuracy: managed.horizontalAccuracy < 0 ? nil : managed.horizontalAccuracy,
                timestamp: managed.locationTimestamp,
                address: managed.locationAddress
            )
        } else {
            location = nil
        }

        return RecordingMetadata(
            languageIdentifier: managed.languageIdentifier,
            title: managed.title,
            tagTimes: tagTimes,
            recordIdentifier: managed.recordID,
            modifiedAt: managed.modifiedAt ?? managed.updatedAt,
            recordedAt: managed.recordedAt ?? managed.createdAt,
            location: location,
            fileFormat: managed.fileFormat,
            sampleRate: managed.sampleRate == 0 ? nil : managed.sampleRate,
            bitDepth: managed.bitDepth == 0 ? nil : Int(managed.bitDepth),
            channelCount: managed.channelCount == 0 ? nil : Int(managed.channelCount),
            inputName: managed.inputName,
            inputUID: managed.inputUID,
            inputPortType: managed.inputPortType,
            noiseReductionMode: managed.noiseReductionMode,
            echoCancellationMode: managed.echoCancellationMode,
            encoding: managed.encoding
        )
    }

    private func cloudRecordID(for recording: RecordingItem) -> String {
        if let recordIdentifier = recording.metadata.recordIdentifier,
           recordIdentifier.isEmpty == false {
            return recordIdentifier
        }

        let date = ISO8601DateFormatter().string(from: recording.createdAt)
        return "\(recording.url.lastPathComponent)|\(date)"
    }

    private func fileByteCount(for url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = values.fileSize else {
            return 0
        }

        return Int64(fileSize)
    }

    private func fileModificationDate(for url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private func removeLocalFiles(at url: URL) {
        for fileURL in [url, url.deletingPathExtension().appendingPathExtension("txt"), url.deletingPathExtension().appendingPathExtension("json")] {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func removeLocalTranscript(for url: URL) {
        try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("txt"))
    }

    private static func makeModel() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = "CloudRecording"
        entity.managedObjectClassName = NSStringFromClass(CloudRecording.self)

        func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = true, external: Bool = false) -> NSAttributeDescription {
            let description = NSAttributeDescription()
            description.name = name
            description.attributeType = type
            description.isOptional = optional
            description.allowsExternalBinaryDataStorage = external
            if optional == false {
                switch type {
                case .stringAttributeType:
                    description.defaultValue = ""
                case .booleanAttributeType:
                    description.defaultValue = false
                case .dateAttributeType:
                    description.defaultValue = Date()
                default:
                    description.defaultValue = 0
                }
            }
            return description
        }

        entity.properties = [
            attribute("recordID", .stringAttributeType, optional: false),
            attribute("fileName", .stringAttributeType, optional: false),
            attribute("fileExtension", .stringAttributeType, optional: false),
            attribute("createdAt", .dateAttributeType, optional: false),
            attribute("duration", .doubleAttributeType, optional: false),
            attribute("title", .stringAttributeType),
            attribute("languageIdentifier", .stringAttributeType),
            attribute("transcript", .stringAttributeType),
            attribute("tagTimesData", .binaryDataAttributeType, external: true),
            attribute("recordedAt", .dateAttributeType),
            attribute("latitude", .doubleAttributeType, optional: false),
            attribute("longitude", .doubleAttributeType, optional: false),
            attribute("altitude", .doubleAttributeType, optional: false),
            attribute("horizontalAccuracy", .doubleAttributeType, optional: false),
            attribute("locationTimestamp", .dateAttributeType),
            attribute("locationAddress", .stringAttributeType),
            attribute("fileFormat", .stringAttributeType),
            attribute("sampleRate", .doubleAttributeType, optional: false),
            attribute("bitDepth", .integer16AttributeType, optional: false),
            attribute("channelCount", .integer16AttributeType, optional: false),
            attribute("inputName", .stringAttributeType),
            attribute("inputUID", .stringAttributeType),
            attribute("inputPortType", .stringAttributeType),
            attribute("noiseReductionMode", .stringAttributeType),
            attribute("echoCancellationMode", .stringAttributeType),
            attribute("encoding", .stringAttributeType),
            attribute("modifiedAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType),
            attribute("fileByteCount", .integer64AttributeType, optional: false),
            attribute("fileModificationDate", .dateAttributeType),
            attribute("audioData", .binaryDataAttributeType, external: true),
            attribute("isDeletedRecord", .booleanAttributeType, optional: false)
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }
}
