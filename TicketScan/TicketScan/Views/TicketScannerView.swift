import SwiftUI
import PhotosUI
import CropViewController

struct TicketScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TicketViewModel
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingCropView = false
    @State private var title = ""
    @State private var location = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var rating = 0
    @State private var category = TicketCategory.other
    @State private var isProcessingOCR = false
    @State private var ocrText = ""
    @State private var showingOCRResults = false
    @State private var showingOCRFeedback = false
    @State private var ocrSuccess = false
    @StateObject private var adManager = AdManager.shared
    @StateObject private var ocrRewardManager = OCRRewardManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 画像表示セクション
                    VStack(spacing: 16) {
                        if let image = selectedImage {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(16)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            showingCropView = true
                                        }
                                    }
                            }
                            .padding(.horizontal, 20)
                            
                            // OCR リワード広告ボタン
                            if !isProcessingOCR {
                                OCRRewardAdView(ticketId: nil) {
                                    withAnimation(.easeInOut) {
                                        performOCR()
                                    }
                                }
                                .padding(.horizontal, 20)
                            } else {
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .tint(.blue)
                                    Text("AIがテキストを認識中...")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            }
                        } else {
                            // 空の状態
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                    )
                                    .frame(height: 250)
                                
                                VStack(spacing: 16) {
                                    Image(systemName: "ticket")
                                        .font(.system(size: 48, weight: .light))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    VStack(spacing: 4) {
                                        Text("チケットを追加")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("カメラまたはライブラリから選択")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // カメラ・ライブラリボタン
                    HStack(spacing: 16) {
                        Button(action: { 
                            withAnimation(.spring()) {
                                showingCamera = true
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)
                                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("カメラ")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button(action: { 
                            withAnimation(.spring()) {
                                showingImagePicker = true
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)
                                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("ライブラリ")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    
                    // フォームセクション
                    VStack(spacing: 20) {
                        Text("チケット情報")
                            .font(.system(size: 20, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            // タイトル
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "textformat")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("タイトル")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                TextField("例：東京ドーム 野球観戦", text: $title)
                                    .textFieldStyle(ModernTextFieldStyle())
                            }
                            
                            // 場所
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "location")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("場所")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                TextField("例：東京ドーム", text: $location)
                                    .textFieldStyle(ModernTextFieldStyle())
                            }
                            
                            // 説明
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("説明")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                TextField("例：巨人 vs 阪神", text: $description)
                                    .textFieldStyle(ModernTextFieldStyle())
                            }
                            
                            // 開催日時
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("開催日時")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                DatePicker("", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .environment(\.locale, Locale(identifier: "ja_JP"))
                            }
                            
                            // 評価
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("評価")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    StarRatingView(rating: $rating, starSize: 24)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // カテゴリ
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "tag")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("カテゴリ")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                Menu {
                                    ForEach(TicketCategory.allCases, id: \.self) { cat in
                                        Button(action: {
                                            category = cat
                                        }) {
                                            HStack {
                                                Image(systemName: cat.icon)
                                                Text(cat.displayName)
                                                if category == cat {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: category.icon)
                                            .foregroundColor(.blue)
                                        Text(category.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
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
            .sheet(isPresented: $showingCropView) {
                if let image = selectedImage {
                    CropView(image: image) { croppedImage in
                        selectedImage = croppedImage
                    }
                }
            }
            .sheet(isPresented: $showingOCRResults) {
                OCRResultsView(
                    ocrText: ocrText,
                    title: $title,
                    location: $location,
                    description: $description,
                    eventDate: $eventDate
                )
            }
            .sheet(isPresented: $showingOCRFeedback) {
                OCRFeedbackView(
                    success: ocrSuccess,
                    extractedText: ocrText,
                    onDismiss: {
                        showingOCRFeedback = false
                        if ocrSuccess && !ocrText.isEmpty {
                            showingOCRResults = true
                        }
                    }
                )
            }
        }
        .onAppear {
            // 新規チケット作成時はOCR状態をリセット
            ocrRewardManager.switchToNewTicket()
        }
    }
    
    private func saveTicket() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let ticket = Ticket(
            title: title,
            location: location,
            description: description,
            imageData: imageData,
            eventDate: eventDate,
            rating: rating,
            category: category
        )
        
        viewModel.addTicket(ticket)
        
        // チケット保存後にインタースティシャル広告を表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            adManager.showInterstitialAd()
        }
        
        dismiss()
    }
    
    private func performOCR() {
        guard let image = selectedImage else { return }
        
        isProcessingOCR = true
        
        OCRService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                isProcessingOCR = false
                
                switch result {
                case .success(let text):
                    ocrText = text
                    
                    // テキストが実際に検出されたかチェック
                    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedText.isEmpty {
                        ocrSuccess = true
                        let ticketInfo = OCRService.shared.extractTicketInfo(from: text)
                        
                        if !ticketInfo.title.isEmpty {
                            title = ticketInfo.title
                        }
                        if !ticketInfo.venue.isEmpty {
                            location = ticketInfo.venue
                        }
                        if let extractedDate = ticketInfo.eventDate {
                            eventDate = extractedDate
                        }
                    } else {
                        ocrSuccess = false
                    }
                    
                    showingOCRFeedback = true
                    
                case .failure(let error):
                    print("OCR Error: \(error.localizedDescription)")
                    ocrSuccess = false
                    ocrText = ""
                    showingOCRFeedback = true
                }
            }
        }
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
            .font(.system(size: 16))
    }
}

struct CropView: UIViewControllerRepresentable {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> CropViewController {
        let cropViewController = CropViewController(image: image)
        cropViewController.delegate = context.coordinator
        cropViewController.aspectRatioPreset = .presetOriginal
        cropViewController.aspectRatioLockEnabled = false
        cropViewController.resetAspectRatioEnabled = true
        cropViewController.rotateButtonsHidden = false
        cropViewController.cropView.cropBoxResizeEnabled = true
        return cropViewController
    }
    
    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CropViewControllerDelegate {
        let parent: CropView
        
        init(_ parent: CropView) {
            self.parent = parent
        }
        
        func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
            parent.onCrop(image)
            cropViewController.dismiss(animated: true)
        }
        
        func cropViewControllerDidCancel(_ cropViewController: CropViewController) {
            cropViewController.dismiss(animated: true)
        }
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