//
//  FlashcardSetDetailView.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 12/1/24.
//

import SwiftUI

struct FlashcardSetDetailView: View {
    let set: FlashcardSetModel // The flashcard set passed to the view

    var body: some View {
        VStack(spacing: 20) {
            Text(set.name)
                .font(.largeTitle)
                .bold()
                .padding()

            List(set.flashcards) { flashcard in
                VStack(alignment: .leading, spacing: 10) {
                    Text("Question: \(flashcard.question)")
                        .font(.headline)
                    Text("Answer: \(flashcard.answer)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 5)
            }

            Spacer()
        }
        .padding()
        .navigationBarTitle("Flashcard Set Details", displayMode: .inline)
    }
}

// Preview for SwiftUI canvas
struct FlashcardSetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFlashcards = [
            FlashcardModel(id: UUID().uuidString, question: "What is Swift?", answer: "A programming language by Apple."),
            FlashcardModel(id: UUID().uuidString, question: "What is Xcode?", answer: "An IDE for macOS."),
        ]
        let sampleSet = FlashcardSetModel(
            id: UUID().uuidString,
            name: "Sample Flashcards",
            groupID: "SampleGroupID",
            flashcards: sampleFlashcards
        )
        return FlashcardSetDetailView(set: sampleSet)
    }
}

