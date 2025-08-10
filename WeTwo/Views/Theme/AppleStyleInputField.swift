import SwiftUI

struct AppleStyleInputField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrection: Bool = true
    var onCommit: (() -> Void)?
    
    @State private var isFocused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isSecure {
                SecureField("", text: $text)
                    .textFieldStyle(AppleTextFieldStyle(
                        placeholder: placeholder,
                        isFocused: $isFocused
                    ))
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .disableAutocorrection(!autocorrection)
                    .onSubmit {
                        onCommit?()
                    }
            } else {
                TextField("", text: $text)
                    .textFieldStyle(AppleTextFieldStyle(
                        placeholder: placeholder,
                        isFocused: $isFocused
                    ))
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .disableAutocorrection(!autocorrection)
                    .onSubmit {
                        onCommit?()
                    }
            }
        }
    }
}

struct AppleTextFieldStyle: TextFieldStyle {
    let placeholder: String
    @Binding var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Floating label
            Text(placeholder)
                .font(.system(size: isFocused ? 12 : 16, weight: .medium))
                .foregroundColor(isFocused ? Color.accentColor : Color(.systemGray))
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Input field
            configuration
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(.label))
                .padding(.top, isFocused ? 4 : 0)
                .padding(.bottom, 12)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = true
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isFocused = false
            }
        }
    }
}

// MARK: - Text Editor Style
struct AppleTextEditorStyle: ViewModifier {
    let placeholder: String
    @Binding var text: String
    @State private var isFocused: Bool = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(.systemGray))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            
            content
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(.label))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isFocused ? Color.accentColor : Color.clear,
                                    lineWidth: 2
                                )
                        )
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = true
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isFocused = false
            }
        }
    }
}

extension TextEditor {
    func appleStyle(placeholder: String, text: Binding<String>) -> some View {
        self.modifier(AppleTextEditorStyle(placeholder: placeholder, text: text))
    }
}

// MARK: - Search Field Style
struct AppleSearchField: View {
    let placeholder: String
    @Binding var text: String
    var onSearch: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.systemGray))
                .font(.system(size: 16, weight: .medium))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(.label))
                .submitLabel(.search)
                .onSubmit {
                    onSearch?()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.systemGray))
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Preview
struct AppleStyleInputField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppleStyleInputField(
                placeholder: "Email",
                text: .constant(""),
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            
            AppleStyleInputField(
                placeholder: "Password",
                text: .constant(""),
                isSecure: true,
                textContentType: .password
            )
            
            AppleStyleInputField(
                placeholder: "Full Name",
                text: .constant("John Doe"),
                textContentType: .name
            )
            
            TextEditor(text: .constant(""))
                .frame(height: 100)
                .modifier(AppleTextEditorStyle(placeholder: "Write your message...", text: .constant("")))
            
            AppleSearchField(
                placeholder: "Search memories...",
                text: .constant("")
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
