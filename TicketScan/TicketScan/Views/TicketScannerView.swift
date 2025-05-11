import SwiftUI
import PhotosUI

struct TicketScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TicketViewModel
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var title = ""
    @State private var location = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "ticket")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("チケットはまだスキャンされていません")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                
                Button(action: { showingCamera = true }) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                        Text("カメラ").font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                    
                Button(action: { showingImagePicker = true }) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                        Text("ライブラリ").font(.caption)
                    }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                
                Section(header: Text("チケット情報")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("タイトル")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("例：東京ドーム 野球観戦", text: $title)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("場所")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("例：東京ドーム", text: $location)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("説明")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("例：巨人 vs 阪神", text: $description)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("チケット追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTicket()
                    }
                    .disabled(selectedImage == nil || title.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary, isPresented: $showingImagePicker)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera, isPresented: $showingCamera)
            }
        }
    }
    
    private func saveTicket() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let ticket = Ticket(
            title: title,
            location: location,
            description: description,
            imageData: imageData
        )
        
        viewModel.addTicket(ticket)
        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
} 