//
//  FlashcardStudyView.swift
//  Group10FinalProject
//
//  Created by qingyang liu on 11/29/24.
//

import SwiftUI

struct FlashcardStudyView: View {
    let flashcardSet: FlashcardSetModel
    @State private var currentIndex = 0
    @State private var showAnswer = false
    @State private var isShuffled = false

    var shuffledFlashcards: [FlashcardModel] {
        isShuffled ? flashcardSet.flashcards.shuffled() : flashcardSet.flashcards
    }

    var body: some View {
        VStack {
            if flashcardSet.flashcards.isEmpty {
                Text("No cards in this set.")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            } else {
                VStack {
                    // Shuffle Toggle
                    Toggle("Shuffle Cards", isOn: $isShuffled)
                        .padding()

                    // Progress View
                    ProgressView(value: Double(currentIndex + 1), total: Double(flashcardSet.flashcards.count))
                        .padding()

                    Text("Card \(currentIndex + 1) of \(flashcardSet.flashcards.count)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top)

                    Spacer()

                    // Show Question or Answer
                    Text(showAnswer ? shuffledFlashcards[currentIndex].answer : shuffledFlashcards[currentIndex].question)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                        .onTapGesture {
                            showAnswer.toggle()
                        }

                    Spacer()

                    // Navigation Buttons
                    HStack {
                        Button(action: previousCard) {
                            Text("Previous")
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(10)
                        }
                        .disabled(currentIndex == 0)

                        Button(action: nextCard) {
                            Text("Next")
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(currentIndex == shuffledFlashcards.count - 1)
                    }
                    .padding()

                    // Restart Button
                    Button("Restart") {
                        currentIndex = 0
                        showAnswer = false
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top)
                    .disabled(currentIndex == 0)
                }
            }
        }
        .padding()
        .navigationTitle(flashcardSet.name)
    }

    // MARK: - Navigation Logic for Flashcards
    private func previousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
            showAnswer = false
        }
    }

    private func nextCard() {
        if currentIndex < shuffledFlashcards.count - 1 {
            currentIndex += 1
            showAnswer = false
        }
    }
}
