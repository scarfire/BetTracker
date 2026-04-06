import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - CSV FileDocument
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType]  { [.commaSeparatedText] }
    static var writableContentTypes: [UTType]  { [.commaSeparatedText] }

    var text: String

    init(text: String = "") { self.text = text }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            self.text = ""; return
        }
        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: text.data(using: .utf8) ?? Data())
    }
}

// MARK: - Export Options Sheet
struct ExportOptionsView: View {
    let allSports: [String]
    @Binding var selectedSports: Set<String>
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export to CSV")
                .font(.title2)
                .padding(.bottom, 4)

            Text("Select sports to include (all statuses exported):")
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(allSports, id: \.self) { sport in
                        Toggle(isOn: Binding(
                            get: { selectedSports.contains(sport) },
                            set: { isOn in
                                if isOn { selectedSports.insert(sport) }
                                else    { selectedSports.remove(sport) }
                            }
                        )) {
                            Text(sport.isEmpty ? "(Blank)" : sport)
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 180)

            HStack {
                Button("Select All")  { selectedSports = Set(allSports) }
                Button("Select None") { selectedSports.removeAll() }
                Spacer()
                Button("Export…") { onExport() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedSports.isEmpty)
            }
            .padding(.top, 6)
        }
        .padding(16)
        .frame(width: 420)
    }
}

// MARK: - Main Grid + Export
struct BetsGridView: View {
    @Query(sort: \Bet.eventDate) private var bets: [Bet]

    @State private var showingExportOptions  = false
    @State private var selectedSports: Set<String> = []
    @State private var showingFileExporter   = false
    @State private var csvDocument           = CSVDocument(text: "")
    @State private var suggestedFilename     = "BetTracker-Export.csv"

    private var allSports: [String] {
        Set(bets.map { $0.sport })
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Bet Tracker — Data Grid")
                    .font(.title2)
                Spacer()
                Button("Export CSV") {
                    selectedSports   = Set(allSports)
                    suggestedFilename = "BetTracker-Export-\(dateStamp()).csv"
                    showingExportOptions = true
                }
            }
            .padding([.horizontal, .top], 12)

            Table(bets) {
                TableColumn("Event Date") { bet in
                    Text(bet.eventDate, format: .dateTime.month().day().year())
                }
                TableColumn("Sport") { bet in
                    Text(bet.sport)
                }
                TableColumn("Wager") { bet in
                    Text(bet.wagerText).lineLimit(1)
                }
                TableColumn("Parlay") { bet in
                    Text(bet.parlaySize <= 1 ? "Straight" : "\(bet.parlaySize)-Leg")
                    .foregroundStyle(bet.parlaySize > 1 ? Color.accentColor : Color.primary)
                }
                TableColumn("Prop") { bet in
                    Text(bet.isProp ? "Yes" : "—")
                        .foregroundStyle(bet.isProp ? .orange : .secondary)
                }
                TableColumn("Bet") { bet in
                    Text(bet.betAmount, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                }
                TableColumn("Payout") { bet in
                    Text(bet.payoutAmount, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                }
                TableColumn("Net") { bet in
                    if let net = bet.net {
                        Text(net, format: .number.precision(.fractionLength(2)))
                            .monospacedDigit()
                            .foregroundStyle(net >= 0 ? .green : .red)
                    } else {
                        Text("Pending").foregroundStyle(.secondary)
                    }
                }
                TableColumn("Created") { bet in
                    Text(bet.createdAt, format: .dateTime.month().day().year())
                }
                TableColumn("Settled") { bet in
                    if let s = bet.settledAt {
                        Text(s, format: .dateTime.month().day().year())
                    } else {
                        Text("—").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
        }
        .frame(minWidth: 1200, minHeight: 650)

        // Options sheet
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(
                allSports: allSports,
                selectedSports: $selectedSports,
                onExport: {
                    let filtered = bets.filter { selectedSports.contains($0.sport) }
                    csvDocument      = CSVDocument(text: makeCSV(from: filtered))
                    showingExportOptions = false
                    DispatchQueue.main.async { showingFileExporter = true }
                }
            )
        }

        // Save dialog
        .fileExporter(
            isPresented: $showingFileExporter,
            document: csvDocument,
            contentType: .commaSeparatedText,
            defaultFilename: suggestedFilename
        ) { _ in }
    }

    // MARK: - CSV generation
    // Column names match import_bets.py exactly

    private func makeCSV(from bets: [Bet]) -> String {
        var lines: [String] = [
            "id,created_at,event_date,settled_at,sport,wager_text,parlay_size,is_prop,bet_amount,payout_amount,original_payout_amount,net"
        ]

        for b in bets {
            let row: [String] = [
                csvEscape(b.id.uuidString),
                csvEscape(isoDateTime(b.createdAt)),
                csvEscape(isoDateOnly(b.eventDate)),
                csvEscape(b.settledAt.map(isoDateTime) ?? ""),
                csvEscape(b.sport),
                csvEscape(b.wagerText),
                "\(b.parlaySize)",
                b.isProp ? "1" : "0",
                fmt(b.betAmount),
                fmt(b.payoutAmount),
                fmt(b.originalPayoutAmount),
                csvEscape(b.net.map(fmt) ?? "")
            ]
            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    // ISO 8601 dates — what import_bets.py expects
    private static let isoDateTimeFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoDateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale   = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "America/New_York")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func isoDateTime(_ date: Date) -> String { Self.isoDateTimeFormatter.string(from: date) }
    private func isoDateOnly(_ date: Date) -> String  { Self.isoDateOnlyFormatter.string(from: date) }
    private func fmt(_ d: Double) -> String           { String(format: "%.2f", d) }

    private func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
