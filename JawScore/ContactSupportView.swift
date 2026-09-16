import SwiftUI

struct ContactSupportView: View {
    enum SubjectOption: String, CaseIterable, Identifiable {
        case general
        case feature
        case bug
        case usage
        case performance
        case ui
        case other

        var id: String { rawValue }

        var title: String {
            switch self {
            case .general: return "General"
            case .feature: return "Feature Suggestion"
            case .bug: return "Bug Report"
            case .usage: return "Usage Question"
            case .performance: return "Performance Issue"
            case .ui: return "UI Improvement"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .general: return "bubble.left.fill"
            case .feature: return "lightbulb.fill"
            case .bug: return "ant.fill"
            case .usage: return "questionmark.circle.fill"
            case .performance: return "gauge.with.dots.needle.67percent"
            case .ui: return "paintpalette.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var subject: SubjectOption = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var statusMessage: String?
    @State private var didSucceed = false

    private let characterLimit = 1000

    private var resolvedSubject: String {
        subject == .other ? customSubject.trimmingCharacters(in: .whitespaces) : subject.title
    }

    private var emailIsValid: Bool {
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email.trimmingCharacters(in: .whitespaces))
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && emailIsValid
            && !resolvedSubject.isEmpty
            && !message.trimmingCharacters(in: .whitespaces).isEmpty
            && message.count <= characterLimit
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                subjectGrid
                nameField
                emailField
                messageField
                submitButton
                if let statusMessage {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(didSucceed ? Color.jsTeal : Color.jsOrange)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                Text("We only use your email to respond to this feedback.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(16)
            .appContentWidth()
            .frame(maxWidth: .infinity)
        }
        .background(Color.jsBase.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subjectGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What is this about?")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(SubjectOption.allCases.filter { $0 != .other }) { option in
                    subjectTile(option)
                }
            }
            subjectTile(.other)
            if subject == .other {
                TextField("Custom subject", text: $customSubject)
                    .padding(12)
                    .background(Color.jsSurfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Custom subject")
            }
        }
    }

    private func subjectTile(_ option: SubjectOption) -> some View {
        Button {
            subject = option
        } label: {
            HStack(spacing: 10) {
                Image(systemName: option.icon)
                    .foregroundStyle(subject == option ? Color.jsTeal : .secondary)
                    .accessibilityHidden(true)
                Text(option.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(subject == option ? Color.jsTealSoft : Color.jsSurfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(subject == option ? Color.jsTeal : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title) subject")
        .accessibilityAddTraits(subject == option ? .isSelected : [])
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Name")
                .font(.subheadline.weight(.semibold))
            TextField("Your name", text: $name)
                .padding(12)
                .background(Color.jsSurfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.white)
                .accessibilityLabel("Your name")
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Email")
                .font(.subheadline.weight(.semibold))
            TextField("you@example.com", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color.jsSurfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.white)
                .accessibilityLabel("Your email address")
            if !email.isEmpty && !emailIsValid {
                Text("Enter a valid email address.")
                    .font(.caption)
                    .foregroundStyle(Color.jsOrange)
            }
        }
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Message")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(message.count) / \(characterLimit)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            TextEditor(text: $message)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.jsSurfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.white)
                .onChange(of: message) { _, newValue in
                    if newValue.count > characterLimit {
                        message = String(newValue.prefix(characterLimit))
                    }
                }
                .accessibilityLabel("Your message")
        }
    }

    private var submitButton: some View {
        Button {
            Task { await send() }
        } label: {
            HStack(spacing: 8) {
                if isSending {
                    ProgressView()
                        .tint(.black)
                }
                Text("Send")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.jsTeal)
        .foregroundStyle(.black)
        .disabled(!canSubmit || isSending)
        .accessibilityLabel("Send feedback")
    }

    private func send() async {
        isSending = true
        statusMessage = nil
        defer { isSending = false }
        do {
            var request = URLRequest(url: URL(string: "https://feedback-board.iocompile67692.workers.dev/api/feedback")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            let payload: [String: String] = [
                "name": name.trimmingCharacters(in: .whitespaces),
                "email": email.trimmingCharacters(in: .whitespaces),
                "subject": resolvedSubject,
                "message": message,
                "app_name": "JawScore"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            didSucceed = true
            statusMessage = "Thank you! Your feedback has been sent."
            name = ""
            email = ""
            message = ""
            customSubject = ""
            subject = .general
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            dismiss()
        } catch {
            didSucceed = false
            statusMessage = "Sending did not go through. Please check your connection and try again."
        }
    }
}
