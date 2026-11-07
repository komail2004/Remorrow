import SwiftUI

struct ContentView: View {
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Capture something important") {
                    TextEditor(text: $draft)
                        .frame(minHeight: 140)
                        .accessibilityLabel("Content to remember")
                    Text("Analysis and reminders will be implemented in upcoming sprints.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Upcoming") {
                    ContentUnavailableView("Nothing saved yet", systemImage: "calendar.badge.clock")
                }
            }
            .navigationTitle("Remorrow")
        }
    }
}
