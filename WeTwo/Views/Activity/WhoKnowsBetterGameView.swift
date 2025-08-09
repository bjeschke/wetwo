//
//  WhoKnowsBetterGameView.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 07.08.25.
//

import SwiftUI

struct WhoKnowsBetterGameView: View {
    @EnvironmentObject var partnerManager: PartnerManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentQuestionIndex = 0
    @State private var player1Score = 0
    @State private var player2Score = 0
    @State private var currentPlayer = 1
    @State private var showingAnswer = false
    @State private var selectedAnswer: String = ""
    @State private var correctAnswer: String = ""
    @State private var isGameComplete = false
    @State private var showingResults = false
    
    private let questions = WhoKnowsBetterQuestions.allQuestions
    private let maxQuestions = 10
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isGameComplete {
                    gameResultsView
                } else {
                    gamePlayView
                }
            }
            .padding()
            .purpleTheme()
            .navigationTitle(NSLocalizedString("game_who_knows_better", comment: "Who Knows Better?"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("close", comment: "Close")) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var gamePlayView: some View {
        VStack(spacing: 25) {
            // Score display
            scoreDisplay
            
            // Progress indicator
            progressIndicator
            
            // Current player indicator
            currentPlayerIndicator
            
            // Question
            questionDisplay
            
            // Answer options
            if !showingAnswer {
                answerOptions
            } else {
                answerResult
            }
            
            // Next button
            if showingAnswer {
                nextButton
            }
            
            Spacer()
        }
    }
    
    private var scoreDisplay: some View {
        HStack(spacing: 30) {
            VStack {
                Text(NSLocalizedString("player_1", comment: "Player 1"))
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(player1Score)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(currentPlayer == 1 ? ColorTheme.accentPink : ColorTheme.cardBackground)
            )
            
            VStack {
                Text("VS")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack {
                Text(NSLocalizedString("player_2", comment: "Player 2"))
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(player2Score)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(currentPlayer == 2 ? ColorTheme.accentPink : ColorTheme.cardBackground)
            )
        }
    }
    
    private var progressIndicator: some View {
        VStack(spacing: 10) {
            HStack {
                Text(NSLocalizedString("question", comment: "Question"))
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(currentQuestionIndex + 1)/\(maxQuestions)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(maxQuestions))
                .progressViewStyle(LinearProgressViewStyle(tint: ColorTheme.accentPink))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(15)
    }
    
    private var currentPlayerIndicator: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(.white)
            Text("\(NSLocalizedString("player", comment: "Player")) \(currentPlayer) \(NSLocalizedString("turn", comment: "turn"))")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .background(ColorTheme.accentPink)
        .cornerRadius(25)
    }
    
    private var questionDisplay: some View {
        VStack(spacing: 15) {
            Text(questions[currentQuestionIndex].question)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .background(ColorTheme.cardBackground)
                .cornerRadius(15)
        }
    }
    
    private var answerOptions: some View {
        VStack(spacing: 15) {
            ForEach(questions[currentQuestionIndex].options, id: \.self) { option in
                Button(action: {
                    selectedAnswer = option
                    checkAnswer()
                }) {
                    Text(option)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ColorTheme.cardBackground)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var answerResult: some View {
        VStack(spacing: 20) {
            if selectedAnswer == correctAnswer {
                // Correct answer
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text(NSLocalizedString("correct_answer", comment: "Correct!"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("+1 \(NSLocalizedString("point", comment: "point"))")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            } else {
                // Wrong answer
                VStack(spacing: 15) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text(NSLocalizedString("wrong_answer", comment: "Wrong answer"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("\(NSLocalizedString("correct_answer_was", comment: "Correct answer was")): \(correctAnswer)")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(15)
    }
    
    private var nextButton: some View {
        Button(action: nextQuestion) {
            Text(currentQuestionIndex < maxQuestions - 1 ? 
                 NSLocalizedString("next_question", comment: "Next Question") : 
                 NSLocalizedString("see_results", comment: "See Results"))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(ColorTheme.accentPink)
                .cornerRadius(15)
        }
    }
    
    private var gameResultsView: some View {
        VStack(spacing: 30) {
            Text("🏆")
                .font(.system(size: 80))
            
            Text(NSLocalizedString("game_complete", comment: "Game Complete!"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                HStack(spacing: 40) {
                    VStack {
                        Text(NSLocalizedString("player_1", comment: "Player 1"))
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(player1Score)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        Text(NSLocalizedString("player_2", comment: "Player 2"))
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(player2Score)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // Winner announcement
                if player1Score > player2Score {
                    Text("\(NSLocalizedString("player_1", comment: "Player 1")) \(NSLocalizedString("wins", comment: "wins"))! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                } else if player2Score > player1Score {
                    Text("\(NSLocalizedString("player_2", comment: "Player 2")) \(NSLocalizedString("wins", comment: "wins"))! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                } else {
                    Text(NSLocalizedString("tie_game", comment: "It's a tie! 🤝"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(20)
            
            VStack(spacing: 15) {
                Button(action: restartGame) {
                    Text(NSLocalizedString("play_again", comment: "Play Again"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ColorTheme.accentPink)
                        .cornerRadius(15)
                }
                
                Button(action: { dismiss() }) {
                    Text(NSLocalizedString("back_to_menu", comment: "Back to Menu"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ColorTheme.cardBackground)
                        .cornerRadius(15)
                }
            }
        }
    }
    
    private func checkAnswer() {
        correctAnswer = questions[currentQuestionIndex].correctAnswer
        showingAnswer = true
        
        if selectedAnswer == correctAnswer {
            if currentPlayer == 1 {
                player1Score += 1
            } else {
                player2Score += 1
            }
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < maxQuestions - 1 {
            currentQuestionIndex += 1
            currentPlayer = currentPlayer == 1 ? 2 : 1
            showingAnswer = false
            selectedAnswer = ""
        } else {
            isGameComplete = true
        }
    }
    
    private func restartGame() {
        currentQuestionIndex = 0
        player1Score = 0
        player2Score = 0
        currentPlayer = 1
        showingAnswer = false
        selectedAnswer = ""
        isGameComplete = false
    }
}

// MARK: - Questions Data
struct WhoKnowsBetterQuestion {
    let question: String
    let options: [String]
    let correctAnswer: String
}

struct WhoKnowsBetterQuestions {
    static let allQuestions: [WhoKnowsBetterQuestion] = [
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_favorite_color", comment: "What is your partner's favorite color?"),
            options: [
                NSLocalizedString("color_blue", comment: "Blue"),
                NSLocalizedString("color_red", comment: "Red"),
                NSLocalizedString("color_green", comment: "Green"),
                NSLocalizedString("color_purple", comment: "Purple")
            ],
            correctAnswer: NSLocalizedString("color_blue", comment: "Blue")
        ),
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_favorite_food", comment: "What is your partner's favorite food?"),
            options: [
                NSLocalizedString("food_pizza", comment: "Pizza"),
                NSLocalizedString("food_pasta", comment: "Pasta"),
                NSLocalizedString("food_sushi", comment: "Sushi"),
                NSLocalizedString("food_burger", comment: "Burger")
            ],
            correctAnswer: NSLocalizedString("food_pizza", comment: "Pizza")
        ),
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_dream_vacation", comment: "Where would your partner like to go on vacation?"),
            options: [
                NSLocalizedString("vacation_beach", comment: "Beach"),
                NSLocalizedString("vacation_mountains", comment: "Mountains"),
                NSLocalizedString("vacation_city", comment: "City"),
                NSLocalizedString("vacation_countryside", comment: "Countryside")
            ],
            correctAnswer: NSLocalizedString("vacation_beach", comment: "Beach")
        ),
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_favorite_music", comment: "What type of music does your partner prefer?"),
            options: [
                NSLocalizedString("music_pop", comment: "Pop"),
                NSLocalizedString("music_rock", comment: "Rock"),
                NSLocalizedString("music_classical", comment: "Classical"),
                NSLocalizedString("music_jazz", comment: "Jazz")
            ],
            correctAnswer: NSLocalizedString("music_pop", comment: "Pop")
        ),
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_pet_peeve", comment: "What is your partner's biggest pet peeve?"),
            options: [
                NSLocalizedString("pet_peeve_loud", comment: "Loud noises"),
                NSLocalizedString("pet_peeve_messy", comment: "Messy spaces"),
                NSLocalizedString("pet_peeve_late", comment: "Being late"),
                NSLocalizedString("pet_peeve_interrupt", comment: "Being interrupted")
            ],
            correctAnswer: NSLocalizedString("pet_peeve_late", comment: "Being late")
        ),
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_favorite_season", comment: "What is your partner's favorite season?"),
            options: [
                NSLocalizedString("season_spring", comment: "Spring"),
                NSLocalizedString("season_summer", comment: "Summer"),
                NSLocalizedString("season_autumn", comment: "Autumn"),
                NSLocalizedString("season_winter", comment: "Winter")
            ],
            correctAnswer: NSLocalizedString("season_summer", comment: "Summer")
        ),
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_favorite_movie_genre", comment: "What is your partner's favorite movie genre?"),
            options: [
                NSLocalizedString("genre_action", comment: "Action"),
                NSLocalizedString("genre_comedy", comment: "Comedy"),
                NSLocalizedString("genre_romance", comment: "Romance"),
                NSLocalizedString("genre_thriller", comment: "Thriller")
            ],
            correctAnswer: NSLocalizedString("genre_comedy", comment: "Comedy")
        ),
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_favorite_hobby", comment: "What is your partner's favorite hobby?"),
            options: [
                NSLocalizedString("hobby_reading", comment: "Reading"),
                NSLocalizedString("hobby_sports", comment: "Sports"),
                NSLocalizedString("hobby_cooking", comment: "Cooking"),
                NSLocalizedString("hobby_gaming", comment: "Gaming")
            ],
            correctAnswer: NSLocalizedString("hobby_reading", comment: "Reading")
        ),
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_favorite_drink", comment: "What is your partner's favorite drink?"),
            options: [
                NSLocalizedString("drink_coffee", comment: "Coffee"),
                NSLocalizedString("drink_tea", comment: "Tea"),
                NSLocalizedString("drink_water", comment: "Water"),
                NSLocalizedString("drink_juice", comment: "Juice")
            ],
            correctAnswer: NSLocalizedString("drink_coffee", comment: "Coffee")
        ),
        WhoKnowsBetterQuestion(
            question: NSLocalizedString("question_favorite_animal", comment: "What is your partner's favorite animal?"),
            options: [
                NSLocalizedString("animal_dog", comment: "Dog"),
                NSLocalizedString("animal_cat", comment: "Cat"),
                NSLocalizedString("animal_bird", comment: "Bird"),
                NSLocalizedString("animal_fish", comment: "Fish")
            ],
            correctAnswer: NSLocalizedString("animal_dog", comment: "Dog")
        )
    ]
}

#Preview {
    WhoKnowsBetterGameView()
        .environmentObject(PartnerManager())
}
