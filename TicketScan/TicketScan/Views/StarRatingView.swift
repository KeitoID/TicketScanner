import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    let maxRating: Int = 5
    let starSize: CGFloat
    let interactive: Bool
    
    init(rating: Binding<Int>, starSize: CGFloat = 20, interactive: Bool = true) {
        self._rating = rating
        self.starSize = starSize
        self.interactive = interactive
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Button(action: {
                    if interactive {
                        rating = index
                    }
                }) {
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.system(size: starSize))
                        .foregroundColor(index <= rating ? .yellow : .gray)
                        .animation(.easeInOut(duration: 0.1), value: rating)
                }
                .disabled(!interactive)
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct StarRatingDisplayView: View {
    let rating: Int
    let starSize: CGFloat
    
    init(rating: Int, starSize: CGFloat = 16) {
        self.rating = rating
        self.starSize = starSize
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundColor(index <= rating ? .yellow : .gray.opacity(0.4))
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: .constant(3))
        StarRatingDisplayView(rating: 4)
        StarRatingView(rating: .constant(0), starSize: 24)
    }
    .padding()
}