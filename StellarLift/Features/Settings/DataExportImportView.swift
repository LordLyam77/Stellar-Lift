import SwiftUI
import SwiftData

public struct ExportPayload: Codable {
    public let appVersion: String
    public let exportedAt: Date
    public let sessions: [ExportSessionDTO]
    public let exercises: [ExportExerciseDTO]
}

public struct ExportSessionDTO: Codable {
    public let id: UUID
    public let date: Date
    public let splitName: String
    public let durationSeconds: Double
    public let totalVolumeKg: Double
    public let exercises: [ExportPerformedDTO]
}

public struct ExportPerformedDTO: Codable {
    public let exerciseName: String
    public let sets: [ExportSetDTO]
}

public struct ExportSetDTO: Codable {
    public let setNumber: Int
    public let weightKg: Double
    public let reps: Int
    public let rpe: Double?
    public let isWarmup: Bool
    public let e1RM: Double
    public let volumeKg: Double
}

public struct ExportExerciseDTO: Codable {
    public let name: String
    public let muscleGroup: String
    public let equipment: String
    public let repLow: Int
    public let repHigh: Int
    public let notes: String
}

public struct DataExportImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var exercises: [Exercise]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var shareURL: URL? = nil
    @State private var showingShareSheet: Bool = false
    @State private var showingImportFilePicker: Bool = false
    @State private var importStatus: String? = nil

    public var body: some View {
        ZStack {
            StarfieldBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Export Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("BACKUP & EXPORT")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)

                        Text("Export all your workout logs, sets, personal records, and custom exercise definitions.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)

                        // Export JSON Button
                        Button {
                            exportJSON()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("Export Complete Backup (JSON)")
                            }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedTheme.primaryAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Export CSV Button
                        Button {
                            exportCSV()
                        } label: {
                            HStack {
                                Image(systemName: "tablecells.fill")
                                Text("Export Spreadsheet (CSV)")
                            }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedTheme.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedTheme.stroke, lineWidth: 1))
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal, 20)

                    // Import Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("RESTORE BACKUP")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)

                        Text("Restore your training logs from a previous Stellar Lift JSON export.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)

                        Button {
                            showingImportFilePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.doc.fill")
                                Text("Import JSON Backup")
                            }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.secondaryAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedTheme.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedTheme.secondaryAccent.opacity(0.5), lineWidth: 1))
                        }

                        if let status = importStatus {
                            Text(status)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedTheme.successPR)
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Data Backup & Export")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showingImportFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    private func exportJSON() {
        let exportSessions = sessions.map { s in
            ExportSessionDTO(
                id: s.id,
                date: s.date,
                splitName: s.splitDayName,
                durationSeconds: s.durationSeconds,
                totalVolumeKg: s.totalVolumeKg,
                exercises: s.performedExercises.map { p in
                    ExportPerformedDTO(
                        exerciseName: p.exerciseName,
                        sets: p.sets.map { set in
                            ExportSetDTO(
                                setNumber: set.setNumber,
                                weightKg: set.weightKg,
                                reps: set.reps,
                                rpe: set.rpe,
                                isWarmup: set.isWarmup,
                                e1RM: set.e1RM,
                                volumeKg: set.volumeKg
                            )
                        }
                    )
                }
            )
        }

        let exportEx = exercises.map { e in
            ExportExerciseDTO(
                name: e.name,
                muscleGroup: e.muscleGroup.rawValue,
                equipment: e.equipment.rawValue,
                repLow: e.defaultRepRangeLow,
                repHigh: e.defaultRepRangeHigh,
                notes: e.notes
            )
        }

        let payload = ExportPayload(
            appVersion: Config.appVersion,
            exportedAt: Date(),
            sessions: exportSessions,
            exercises: exportEx
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(payload) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("StellarLift_Backup_\(dateStamp()).json")
            try? data.write(to: tempURL)
            shareURL = tempURL
            showingShareSheet = true
        }
    }

    private func exportCSV() {
        var csv = "Session Date,Split,Exercise,Set Number,Weight (kg),Reps,RPE,Warmup,e1RM,Volume (kg)\n"

        for s in sessions where s.isFinished {
            let dateStr = s.date.formatted(date: .numeric, time: .omitted)
            for p in s.sortedPerformedExercises {
                for set in p.sortedSets {
                    let rpeStr = set.rpe != nil ? "\(set.rpe!)" : ""
                    let line = "\"\(dateStr)\",\"\(s.splitDayName)\",\"\(p.exerciseName)\",\(set.setNumber),\(set.weightKg),\(set.reps),\(rpeStr),\(set.isWarmup),\(String(format: "%.1f", set.e1RM)),\(String(format: "%.1f", set.volumeKg))\n"
                    csv.append(line)
                }
            }
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("StellarLift_Workouts_\(dateStamp()).csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        shareURL = tempURL
        showingShareSheet = true
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let selectedURL = urls.first else { return }

        guard selectedURL.startAccessingSecurityScopedResource() else { return }
        defer { selectedURL.stopAccessingSecurityScopedResource() }

        if let data = try? Data(contentsOf: selectedURL),
           let payload = try? JSONDecoder().decode(ExportPayload.self, from: data) {
            importStatus = "Successfully verified backup from \(payload.exportedAt.formatted(date: .abbreviated, time: .omitted)) (\(payload.sessions.count) sessions)."
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
        } else {
            importStatus = "Invalid backup file format."
        }
    }

    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    public let items: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
