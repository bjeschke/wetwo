//
//  AddMemoryView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import SwiftUI

struct AddMemoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var selectedMood: MoodLevel = .happy
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Add New Memory")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(.label))
                        
                        Text("Capture this special moment")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(.systemGray))
                    }
                    .padding(.top, 20)
                    
                    // Input Fields
                    VStack(spacing: 20) {
                        AppleStyleInputField(
                            placeholder: "Memory Title",
                            text: $title,
                            autocapitalization: .sentences
                        )
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 120)
                            .modifier(AppleTextEditorStyle(placeholder: "Describe this memory...", text: $description))
                    }
                    .padding(.horizontal, 20)
                    
                    // Date Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When did this happen?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(.label))
                        
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Mood Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How did you feel?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(.label))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(MoodLevel.allCases, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    VStack(spacing: 8) {
                                        Text(mood.emoji)
                                            .font(.system(size: 24))
                                        
                                        Text(mood.description)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(selectedMood == mood ? .white : Color(.label))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedMood == mood ? Color.accentColor : Color(.systemGray6))
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Photo Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Photos")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(.label))
                            
                            Spacer()
                            
                            Button("Add Photos") {
                                showingImagePicker = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentColor)
                        }
                        
                        if selectedImage == nil {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color(.systemGray))
                                    
                                    Text("Add photos to your memory")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(.systemGray))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        )
                                )
                            }
                        } else {
                            if let image = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Button(action: {
                                        selectedImage = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Save Button
                    Button(action: saveMemory) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save Memory")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor)
                        )
                        .opacity(isLoading ? 0.7 : 1.0)
                    }
                    .disabled(isLoading || title.isEmpty)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.accentColor))
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoPickerView(selectedImage: $selectedImage)
        }
    }
    
    private func saveMemory() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            dismiss()
        }
    }
}

struct AddMemoryView_Previews: PreviewProvider {
    static var previews: some View {
        AddMemoryView()
    }
} 