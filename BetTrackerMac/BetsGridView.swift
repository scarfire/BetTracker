import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - CSV FileDocument
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            self.text = ""
            return
        }
        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return .init(regularFileWithContents: data)
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

            Text("Select one or more sports to include:")
                .foregroundStyle(.secondary)

            // Simple checkbox list (works well on macOS)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(allSports, id: \.self) { sport in
                        Toggle(isOn: Binding(
                            get: { selectedSports.contains(sport) },
                            set: { isOn in
                                if isOn { selectedSports.insert(sport) }
                                else { selectedSports.remove(sport) }
                            }
                        )) {
                            Text(sport.isEmpty ? "(Blank)" : sport)
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 220)

            HStack {
                Button("Select All") {
                    selectedSports = Set(allSports)
                }

                Button("Select None") {
                    selectedSports.removeAll()
                }

                Spacer()

                Button("Export…") {
                    onExport()
                }
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

    // Export UI state
    @State private var showingExportOptions = false
    @State private var selectedSports: Set<String> = []
    @State private var showingFileExporter = false
    @State private var csvDocument = CSVDocument(text: "")
    @State private var suggestedFilename = "BetTracker-Export.csv"

    private var allSports: [String] {
        let unique = Set(bets.map { $0.sport })
        return unique.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Bet Tracker - Data Grid")
                    .font(.title2)
                Spacer()
                Button("Export CSV") {
                    // Default selection: all sports
                    selectedSports = Set(allSports)
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
                TableColumn("Bet Amount") { bet in
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
                    } else {
                        Text("Pending").foregroundStyle(.secondary)
                    }
                }
                TableColumn("Created") { bet in
                    Text(bet.createdAt, format: .dateTime.month().day().year())
                }
                TableColumn("Settled") { bet in
                    if let settledAt = bet.settledAt {
                        Text(settledAt, format: .dateTime.month().day().year())
                    } else {
                        Text("—").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
        }
        .frame(minWidth: 1100, minHeight: 650)

        // 1) Options sheet
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(
                allSports: allSports,
                selectedSports: $selectedSports,
                onExport: {
                    let filtered = bets.filter { bet in
                        selectedSports.contains(bet.sport) &&
                        (bet.settledAt != nil || bet.net != nil)   // settled only
                    }

                    csvDocument = CSVDocument(text: makeCSV(from: filtered))

                    // 1) Close the options sheet first
                    showingExportOptions = false

                    // 2) Then present the Save dialog on the next runloop tick
                    DispatchQueue.main.async {
                        showingFileExporter = true
                    }
                }
            )
        }

        // 2) Save dialog
        .fileExporter(
            isPresented: $showingFileExporter,
            document: csvDocument,
            contentType: .commaSeparatedText,
            defaultFilename: suggestedFilename
        ) { result in
            // You can add a toast/alert here if you want
            // result: .success(URL) or .failure(Error)
        }
    }

    // MARK: - CSV generation

    private func makeCSV(from bets: [Bet]) -> String {
        // Header row
        var lines: [String] = []
        lines.append([
            "id",
            "createdAt",
            "eventDate",
            "settledAt",
            "sport",
            "wagerText",
            "betAmount",
            "payoutAmount",
            "originalPayoutAmount",
            "net"
        ].joined(separator: ","))

        // Data rows
        for b in bets {
            let row: [String] = [
                csvEscape(b.id.uuidString),
                csvEscape(localDateTime(b.createdAt)),
                csvEscape(localDateOnly(b.eventDate)),
                csvEscape(b.settledAt.map(localDateTime) ?? ""),
                csvEscape(b.sport),
                csvEscape(b.wagerText),
                csvEscape(formatMoney(b.betAmount)),
                csvEscape(formatMoney(b.payoutAmount)),
                csvEscape(formatMoney(b.originalPayoutAmount)),
                csvEscape(b.net.map(formatMoney) ?? "")
            ]
            lines.append(row.joined(separator: ","))
        }

        // Use \n (Excel/Numbers handle it fine on macOS)
        return lines.joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        // Quote if it contains comma, quote, or newline. Double internal quotes.
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            let doubled = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        } else {
            return value
        }
    }

    private static let localDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    private static let localDateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()

    private func localDateTime(_ date: Date) -> String {
        Self.localDateTimeFormatter.string(from: date)
    }

    private func localDateOnly(_ date: Date) -> String {
        Self.localDateOnlyFormatter.string(from: date)
    }

    private func formatMoney(_ d: Double) -> String {
        // Keep it simple and stable for CSV (avoid locale commas)
        String(format: "%.2f", d)
    }

    private func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

