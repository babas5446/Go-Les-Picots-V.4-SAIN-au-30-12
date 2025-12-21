//
//  ImagePickerView.swift
//  Go les Picots - Module 1 Phase 2
//
//  Composant pour sélectionner une image depuis :
//  - La galerie photos (photoLibrary)
//  - La caméra (camera)
//
//  Utilise UIViewControllerRepresentable pour intégrer UIImagePickerController
//
//  Created: 2024-12-10
//

import SwiftUI
import UIKit

struct ImagePickerView: UIViewControllerRepresentable {
    
    // MARK: - Bindings
    
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    
    // MARK: - Configuration
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Pas de mise à jour nécessaire
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            // Récupérer l'image éditée ou originale
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Vérification disponibilité caméra

extension ImagePickerView {
    
    /// Vérifie si la caméra est disponible sur l'appareil
    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    /// Vérifie si la galerie photos est disponible
    static var isPhotoLibraryAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var image: UIImage? = nil
        
        var body: some View {
            VStack {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else {
                    Text("Aucune image sélectionnée")
                }
                
                Button("Sélectionner une image") {
                    // Preview seulement
                }
            }
        }
    }
    
    return PreviewWrapper()
}
