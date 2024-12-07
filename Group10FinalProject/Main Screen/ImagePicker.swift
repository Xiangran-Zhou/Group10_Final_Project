//
//  ImagePicker.swift
//  Group10FinalProject
//
//  Created by user264785 on 11/22/24.
//


import SwiftUIimport UIKitstruct ImagePicker: UIViewControllerRepresentable {    var sourceType: UIImagePickerController.SourceType    @Binding var selectedImage: UIImage?    @Environment(\.presentationMode) private var presentationMode    func makeUIViewController(context: Context) -> UIImagePickerController {        let picker = UIImagePickerController()        picker.sourceType = sourceType        picker.delegate = context.coordinator        return picker    }    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}    func makeCoordinator() -> Coordinator {        Coordinator(self)    }    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {        var parent: ImagePicker        init(_ parent: ImagePicker) {            self.parent = parent        }        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {            if let image = info[.originalImage] as? UIImage {                parent.selectedImage = image            }            parent.presentationMode.wrappedValue.dismiss()        }        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {            parent.presentationMode.wrappedValue.dismiss()        }    }}