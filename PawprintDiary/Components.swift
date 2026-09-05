import SwiftUI
import PhotosUI
import UIKit

struct PetAvatar: View {
    let pet: Pet
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let data = pet.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: pet.species.symbol)
                    .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.caramel)
            }
        }
        .frame(width: size, height: size)
        .background(AppTheme.honeySoft)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.31, style: .continuous))
        .accessibilityLabel("\(pet.name)的头像")
    }
}

struct ProductPhoto: View {
    let data: Data?
    let kind: RecordKind
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: kind.symbol)
                    .font(.system(size: size * 0.34, weight: .semibold, design: .rounded))
                    .foregroundStyle(iconColor)
            }
        }
        .frame(width: size, height: size)
        .background(iconBackground)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
        .clipped()
    }

    private var iconBackground: Color {
        switch kind {
        case .deworm: AppTheme.sageSoft
        case .vaccine: Color.blue.opacity(0.10)
        case .food: AppTheme.honeySoft
        case .taste: AppTheme.berrySoft
        case .bath: Color.cyan.opacity(0.11)
        }
    }

    private var iconColor: Color {
        switch kind {
        case .deworm: .green.opacity(0.65)
        case .vaccine: .blue.opacity(0.65)
        case .food: AppTheme.caramel
        case .taste: .pink.opacity(0.70)
        case .bath: .cyan.opacity(0.72)
        }
    }
}

struct PetSwitcher: View {
    @Environment(AppStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let label: String

    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }

    var body: some View {
        if let pet = store.activePet {
            Menu {
                ForEach(store.pets) { option in
                    Button {
                        store.selectPet(option)
                    } label: {
                        Label(option.name, systemImage: option.id == pet.id ? "checkmark.circle.fill" : option.species.symbol)
                    }
                }
            } label: {
                HStack(spacing: isExpanded ? 15 : 11) {
                    PetAvatar(pet: pet, size: isExpanded ? 56 : 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label).font(isExpanded ? .caption : .caption2).foregroundStyle(AppTheme.caramel)
                        Text(pet.name).font(isExpanded ? .title3 : .headline).foregroundStyle(AppTheme.ink)
                        Text("\(pet.breed) · \(pet.gender.rawValue)")
                            .font(isExpanded ? .caption : .caption2).foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Text("切换").font(isExpanded ? .body : .caption).fontWeight(.semibold).foregroundStyle(AppTheme.caramel)
                    Image(systemName: "chevron.down").font(isExpanded ? .body : .caption2).foregroundStyle(AppTheme.secondaryText)
                }
                .roundedCard(radius: isExpanded ? 23 : 19, padding: isExpanded ? 12 : 8)
            }
            .buttonStyle(.plain)
        }
    }
}

struct RecordRowView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let record: LifeRecord
    @State private var showPhoto = false

    private var isExpanded: Bool { AppLayout.isExpanded(horizontalSizeClass) }

    var body: some View {
        HStack(spacing: isExpanded ? 16 : 12) {
            Button { if record.photoData != nil { showPhoto = true } } label: {
                ProductPhoto(data: record.photoData, kind: record.kind, size: isExpanded ? 68 : 54)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(record.photoData == nil ? "暂无产品照片" : "查看产品大图")

            VStack(alignment: .leading, spacing: 4) {
                Text(record.title).font(isExpanded ? .headline : .subheadline).fontWeight(.semibold).lineLimit(1)
                Text(record.detail).font(isExpanded ? .caption : .caption2).foregroundStyle(AppTheme.secondaryText).lineLimit(2)
            }
            Spacer(minLength: 6)
            Text(record.date, format: .dateTime.month().day())
                .font(isExpanded ? .caption : .caption2).foregroundStyle(AppTheme.secondaryText)
        }
        .roundedCard(radius: isExpanded ? 24 : 20, padding: isExpanded ? 14 : 10)
        .sheet(isPresented: $showPhoto) {
            PhotoViewer(data: record.photoData, title: record.title)
        }
    }
}

struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let data: Data?
    let title: String

    var body: some View {
        NavigationStack {
            Group {
                if let data, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFit().padding()
                } else {
                    ContentUnavailableView("暂无照片", systemImage: "photo")
                }
            }
            .background(Color.black.opacity(0.93).ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly)
                }
            }
        }
    }
}

struct HalfStarRating: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    let full = Double(star)
                    rating = rating == full ? full - 0.5 : full
                } label: {
                    Image(systemName: symbol(for: star))
                        .font(.title3)
                        .foregroundStyle(AppTheme.honey)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(star)星")
            }
            Spacer()
            Text(rating, format: .number.precision(.fractionLength(1)))
                .font(.subheadline).fontWeight(.semibold).foregroundStyle(AppTheme.caramel)
        }
    }

    private func symbol(for star: Int) -> String {
        let delta = rating - Double(star - 1)
        if delta >= 1 { return "star.fill" }
        if delta >= 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var imageData: Data?

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.78)
            }
            parent.dismiss()
        }
    }
}

struct PhotoInputSection: View {
    @Binding var imageData: Data?
    @State private var item: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("照片（可选）").font(.caption).fontWeight(.semibold)
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable().scaledToFill().frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            HStack {
                PhotosPicker(selection: $item, matching: .images) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("拍照", systemImage: "camera") {
                    showCamera = true
                }
                .buttonStyle(.borderless)
            }
            .font(.subheadline).fontWeight(.semibold)
        }
        .task(id: item) {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                imageData = image.jpegData(compressionQuality: 0.78)
            }
        }
        .sheet(isPresented: $showCamera) { CameraPicker(imageData: $imageData).ignoresSafeArea() }
    }
}
