import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var conversionCount = 0
    @State private var showCopySuccess = false

    private let deasciifier = TurkishDeasciifier()
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header - always stays at top
            VStack(alignment: .leading, spacing: 2) {
                Text("Turkish Deasciifier")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Global Hotkey: ⌥⌘T")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 12)
            
            // Scrollable content area
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Input area
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Input:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $inputText)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 120) // ~8 lines at default text size
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: inputText) { newValue in
                                convertText(newValue)
                            }
                    }
                    
                    // Output area - always reserve space
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Output:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if !outputText.isEmpty {
                                // Copy button with success feedback
                                Button(action: {
                                    copyToClipboard()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: showCopySuccess ? "checkmark" : "doc.on.clipboard")
                                        Text(showCopySuccess ? "Copied!" : "Copy")
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(showCopySuccess ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                                    .foregroundColor(showCopySuccess ? .green : .blue)
                                    .cornerRadius(4)
                                    .animation(.easeInOut(duration: 0.2), value: showCopySuccess)
                                }
                                .buttonStyle(.plain)
                                
                                if conversionCount > 0 {
                                    Text("✓ \(conversionCount) characters converted")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.8))
                                        .cornerRadius(3)
                                } else {
                                    Text("No changes needed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if !outputText.isEmpty {
                            ScrollView {
                                Text(outputText)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                                    .textSelection(.enabled)
                            }
                            .frame(height: 120) // ~8 lines to match input
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        } else {
                            // Placeholder for output area
                            Text("Converted text will appear here...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                                .frame(height: 120) // ~8 lines to match input
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            // Fixed footer
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Select text anywhere and press ⌥⌘T to convert")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .padding(.top, 8)
        }
        .frame(width: 380, height: 440)
    }
    
    private func convertText(_ text: String) {
        guard !text.isEmpty else {
            outputText = ""
            conversionCount = 0
            showCopySuccess = false // Reset copy success when clearing
            return
        }

        let converted = deasciifier.convertToTurkish(text)
        outputText = converted

        // Reset copy success when text changes
        showCopySuccess = false

        // Count conversions
        let originalChars = Array(text)
        let convertedChars = Array(converted)
        var count = 0

        for i in 0..<min(originalChars.count, convertedChars.count) {
            if originalChars[i] != convertedChars[i] {
                count += 1
            }
        }

        conversionCount = count
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(outputText, forType: .string)

        // Show success feedback
        showCopySuccess = true

        // Reset after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopySuccess = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}